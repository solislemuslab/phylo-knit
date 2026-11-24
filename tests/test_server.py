"""Tests for the Flask routes in Server.py, using Flask's test client.

Importing Server starts Julia (and on the very first run installs
PhyloNetworks), so all tests here are marked "julia" and share one client.
Skip them with:  pytest -m "not julia"
"""
import contextlib
import io
import os
import re

import pytest

pytestmark = pytest.mark.julia

INPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "src", "InputFiles")
EXAMPLES = sorted(os.listdir(INPUT_DIR))
NEWICK_FILES = [n for n in EXAMPLES if n.startswith("parenthetical_")]
TRIPLET_FILES = [n for n in EXAMPLES if n.startswith("triplets_")]
HYDE_FILES = [n for n in EXAMPLES if n.startswith("hyde_")]


@pytest.fixture(scope="module")
def client():
    with contextlib.redirect_stdout(io.StringIO()):
        import Server
    return Server.app.test_client()


def post(client, url, body):
    """POST a JSON body, hiding the server's debug printing."""
    with contextlib.redirect_stdout(io.StringIO()):
        return client.post(url, json=body)


def is_clear_error(response):
    """A client error (4xx) with a JSON message the web page can show."""
    data = response.get_json(silent=True) or {}
    return 400 <= response.status_code < 500 and "error" in data


def dot_leaves(dot):
    edges = re.findall(r"^(\S+) -> (\S+)$", dot, flags=re.MULTILINE)
    return {c for _, c in edges} - {p for p, _ in edges}


def newick_leaves(newick):
    """Leaf names in a Newick string (names right after "(" or ",";
    hybrid labels like #H1 are not counted)."""
    return set(re.findall(r"(?<=[(,])([^(),:;#\s]+)", newick))


# --- /uploadNewick/ -----------------------------------------------------------

@pytest.mark.parametrize("filename", NEWICK_FILES)
def test_upload_newick_examples(client, filename, read_input):
    r = post(client, "/uploadNewick/", {"text": read_input(filename).strip()})
    assert r.status_code == 200
    data = r.get_json()
    assert "->" in data["dot"]
    assert data["newick"].endswith(";")
    assert data["rootname"]


def test_upload_newick_without_semicolon(client):
    r = post(client, "/uploadNewick/", {"text": "((A,B),C)"})
    assert r.status_code == 200
    assert dot_leaves(r.get_json()["dot"]) == {"A", "B", "C"}


def test_upload_invalid_newick_gives_clear_error(client):
    assert is_clear_error(post(client, "/uploadNewick/", {"text": "((A,B"}))


@pytest.mark.xfail(strict=True, reason="known bug: empty input crashes the "
                   "server (jsonify is given a set instead of a dict)")
def test_upload_empty_newick_gives_clear_error(client):
    assert is_clear_error(post(client, "/uploadNewick/", {"text": ""}))


def test_small_branch_lengths_keep_leaf_names(client):
    r = post(client, "/uploadNewick/", {"text": "((A:1e-5,B:1),C:1);"})
    assert dot_leaves(r.get_json()["dot"]) == {"A", "B", "C"}


# --- /upload/ (triplets) ------------------------------------------------------

@pytest.mark.parametrize("filename", TRIPLET_FILES)
def test_upload_triplet_examples(client, filename, read_input):
    r = post(client, "/upload/", {"text": read_input(filename)})
    assert r.status_code == 200
    assert r.get_json()["newick"].strip().endswith(";")


def test_upload_invalid_triplets_gives_clear_error(client):
    assert is_clear_error(post(client, "/upload/", {"text": "A A B\nA B C\n"}))


def test_upload_triplets_with_too_few_names_gives_clear_error(client):
    assert is_clear_error(post(client, "/upload/", {"text": "A B\nA B C\n"}))


def test_upload_empty_triplets_gives_clear_error(client):
    assert is_clear_error(post(client, "/upload/", {"text": ""}))


# --- /uploadHyde/ --------------------------------------------------------------

def upload_hyde(client, text, threshold="0.05", backbone=""):
    # the web page sends the threshold as the text typed by the user
    return post(client, "/uploadHyde/",
                {"text": text, "threshold": threshold, "backbone": backbone})


@pytest.mark.parametrize("filename", HYDE_FILES)
def test_upload_hyde_examples(client, filename, read_input):
    r = upload_hyde(client, read_input(filename))
    assert r.status_code == 200
    assert r.get_json()["newick"].strip().endswith(";")


@pytest.mark.java
def test_upload_hyde_with_backbone_tree(client, read_input):
    r = upload_hyde(client, read_input("hyde_old_4_taxa_example.txt"),
                    backbone="((2,(3,4)),(5,6));")
    assert r.status_code == 200
    assert newick_leaves(r.get_json()["newick"]) == {"2", "3", "4", "5", "6"}


@pytest.mark.java
def test_upload_hyde_with_backbone_network(client, read_input):
    # A backbone network is reduced to its major tree. (Its "#" also used to
    # cut the backbone short when it was sent in the URL.)
    r = upload_hyde(client, read_input("hyde_old_4_taxa_example.txt"),
                    backbone="((2,(3)#H1:::0.3),(#H1:::0.7,(4,(5,6))));")
    assert r.status_code == 200
    newick = r.get_json()["newick"]
    assert newick_leaves(newick) == {"2", "3", "4", "5", "6"}
    # the web page draws the result by sending it to /uploadNewick/
    assert post(client, "/uploadNewick/", {"text": newick.strip()}).status_code == 200


def test_upload_hyde_with_invalid_backbone_gives_clear_error(client, read_input):
    r = upload_hyde(client, read_input("hyde_old_4_taxa_example.txt"),
                    backbone="((2,(3,4)")
    assert is_clear_error(r)


@pytest.mark.xfail(strict=True, reason="known bug: an unrecognised HyDe format "
                   "crashes the server")
def test_upload_hyde_wrong_format_gives_clear_error(client, read_input):
    r = upload_hyde(client, read_input("triplets_example1.txt"))
    assert is_clear_error(r)


# --- /getUserAdjustedParenthetical/ (re-root, remove leaves) ------------------

def adjust(client, newick, new_root="", removed=()):
    return post(client, "/getUserAdjustedParenthetical/",
                {"text": newick, "new_root": new_root, "removed_nodes": list(removed)})


def test_reroot_tree(client):
    r = adjust(client, "((A,B),(C,D));", new_root="C")
    assert r.status_code == 200
    assert r.get_json()["newick"] == "(C,(D,(A,B)))root;"


def test_reroot_network(client):
    r = adjust(client, "((A,(B)#H1),(#H1,(C,D)));", new_root="D")
    assert r.status_code == 200
    assert r.get_json()["newick"] == "(D,(C,(#H1,(A,(B)#H1))))root;"


def test_reroot_below_hybrid_gives_clear_error(client):
    # B sits below the reticulation; rooting there would invert it
    assert is_clear_error(adjust(client, "((A,(B)#H1),(#H1,(C,D)));", new_root="B"))


def test_remove_leaf(client):
    r = adjust(client, "((A,B),(C,D));", removed=["A"])
    assert r.status_code == 200
    assert r.get_json()["newick"] == "((C,D),B)root;"


# --- /getPDF/ -----------------------------------------------------------------

def test_pdf_export(client):
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="50" height="50">'
           '<circle cx="25" cy="25" r="20"/></svg>')
    r = post(client, "/getPDF/", {"svg": svg})
    assert r.status_code == 200
    assert r.data.startswith(b"%PDF")
