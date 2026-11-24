"""Tests for converting HyDe output to triplets (ServerAction.parseHydeToTriplets).

For a hybrid H with parents P1 and P2 whose p-value is below the threshold,
both triplets H P1 | P2 and H P2 | P1 are produced. Taxa that are not in a
significant hybrid relationship get one triplet per set of three, taken from
the backbone tree if one is given, otherwise chosen arbitrarily.
"""
import contextlib
import io
import os
from itertools import combinations

import pytest

import ServerAction

NO_BACKBONE = "none_provided"   # what the web page sends when there is no backbone

INPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "src", "InputFiles")
HYDE_EXAMPLE_FILES = sorted(n for n in os.listdir(INPUT_DIR) if n.startswith("hyde_"))


def parse(hyde_text, threshold=0.05, backbone=NO_BACKBONE):
    """Run parseHydeToTriplets (hiding its debug printing) and return the
    triplets as a set of (frozenset({x, y}), z), meaning xy|z."""
    with contextlib.redirect_stdout(io.StringIO()):
        text = ServerAction.parseHydeToTriplets(hyde_text, threshold, backbone)
    result = set()
    for line in text.split("\n"):
        if line.strip():
            x, y, z = line.split()[:3]
            result.add((frozenset({x, y}), z))
    return result


def trip(x, y, z):
    """The triplet xy|z."""
    return (frozenset({x, y}), z)


def taxa(triplets):
    return {t for pair, z in triplets for t in (*pair, z)}


def covered_sets(triplets):
    """Sets of three taxa that have at least one triplet."""
    return {frozenset({*pair, z}) for pair, z in triplets}


# --- Old HyDe format ("Hybrid: 3 Parents: 2 and 4  z  p") ---------------------

def test_old_format_significant_hybrids_give_both_triplets(read_input):
    result = parse(read_input("hyde_old_4_taxa_example.txt"))
    # Hybrid 3, parents 2 and 4 (p = 0.0022)
    assert {trip("3", "2", "4"), trip("3", "4", "2")} <= result
    # Hybrid 4, parents 2 and 3 (p = 0.0022)
    assert {trip("4", "2", "3"), trip("4", "3", "2")} <= result


def test_old_format_nonsignificant_rows_give_one_triplet(read_input):
    result = parse(read_input("hyde_old_4_taxa_example.txt"))
    # Hybrid 3, parents 2 and 5 has p = 0.57: only one triplet for {2, 3, 5}
    on_235 = [t for t in result if covered_sets([t]) == {frozenset({"2", "3", "5"})}]
    assert len(on_235) == 1


def test_without_backbone_every_set_of_three_taxa_is_covered(read_input):
    result = parse(read_input("hyde_old_4_taxa_example.txt"))
    all_sets = {frozenset(s) for s in combinations(sorted(taxa(result)), 3)}
    assert covered_sets(result) == all_sets


def test_threshold_zero_gives_no_hybrid_triplets(read_input):
    result = parse(read_input("hyde_old_4_taxa_example.txt"), threshold=0)
    # with no significant hybrids there is exactly one triplet per set of three
    assert len(result) == len(covered_sets(result))


# --- New HyDe format (header line, tab or comma separated) ------------------

def test_new_format_filtered_output(read_input):
    # sp2 is a hybrid of sp1 and sp3 (p = 0.012); the second row has p = 1
    result = parse(read_input("hyde_filtered_text_example.txt"))
    assert result == {trip("sp2", "sp1", "sp3"), trip("sp2", "sp3", "sp1")}


def test_new_format_comma_separated(read_input):
    # One row, p = 1.0: a single (arbitrary) triplet
    result = parse(read_input("hyde_unfiltered_3_taxa.csv"))
    assert len(result) == 1
    assert taxa(result) == {"P1", "P2", "HYB"}


@pytest.mark.parametrize("filename", HYDE_EXAMPLE_FILES)
def test_all_example_files_parse(filename, read_input):
    assert len(parse(read_input(filename))) > 0


@pytest.mark.parametrize("filename", ["triplets_example1.txt",
                                      "parenthetical_10_taxa_with_2_hybrids.net"])
def test_other_input_files_give_a_clear_error(filename, read_input):
    with pytest.raises(ValueError, match="does not look like HyDe output"):
        parse(read_input(filename))


@pytest.mark.parametrize("text", [
    "hello there\nthis is not hyde\nat all, really\n",   # pandas cannot read it
    "a b c\nd e\nf g h i j\n",                          # ragged rows
    "  \n",                                              # nothing but whitespace
])
def test_unreadable_text_gives_a_clear_error(text):
    with pytest.raises(ValueError, match="does not look like HyDe output"):
        parse(text)


# --- Backbone tree (runs NewickToTriplet.jar) --------------------------------

@pytest.mark.java
def test_backbone_tree_triplets_are_added(read_input):
    result = parse(read_input("hyde_old_4_taxa_example.txt"),
                   backbone="((2,(3,4)),(5,6));")
    # hybrid triplets are still there
    assert {trip("3", "2", "4"), trip("3", "4", "2")} <= result
    # and the backbone's own triplets are added
    assert {trip("5", "6", "2"), trip("3", "4", "5"), trip("2", "3", "6")} <= result


@pytest.mark.java
def test_backbone_works_from_any_folder_and_leaves_no_files(tmp_path, monkeypatch, read_input):
    monkeypatch.chdir(tmp_path)
    result = parse(read_input("hyde_old_4_taxa_example.txt"),
                   backbone="((2,(3,4)),(5,6));")
    assert trip("5", "6", "2") in result
    assert os.listdir(tmp_path) == []


def test_backbone_network_is_rejected(read_input):
    # The server reduces a backbone network to its major tree before calling
    # parseHydeToTriplets (see test_server.py); a network here would add its
    # hybrid label (#H1) as a fake taxon
    with pytest.raises(ValueError):
        parse(read_input("hyde_old_4_taxa_example.txt"),
              backbone="((2,(3)#H1),(#H1,(4,(5,6))));")
