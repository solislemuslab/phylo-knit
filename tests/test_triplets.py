"""Tests for triplet handling in ServerAction: duplicate removal and
building a network with Lev1athan (tripletsToNewick).

A triplet line "x y z [weight]" means x and y are closer to each other
than to z (written xy|z).
"""
import os
import tempfile

import pytest

import ServerAction


def triplet_lines(text):
    """Non-empty lines of a triplet string."""
    return [line for line in text.split("\n") if line.strip()]


# --- removeDupTriplets ------------------------------------------------------

def test_duplicate_with_swapped_pair_is_removed():
    # "A B C" and "B A C" are the same triplet (AB|C); the first one is kept
    result = ServerAction.removeDupTriplets("A B C\nB A C\n")
    assert triplet_lines(result) == ["A B C"]


def test_triplets_with_different_outgroups_are_kept():
    # AB|C and AC|B are different triplets
    result = ServerAction.removeDupTriplets("A B C\nA C B\n")
    assert triplet_lines(result) == ["A B C", "A C B"]


def test_weighted_triplets_are_kept():
    result = ServerAction.removeDupTriplets("A B C 2\nA D C 1\n")
    assert triplet_lines(result) == ["A B C 2", "A D C 1"]


def test_line_with_two_names_gives_a_clear_error():
    with pytest.raises(ValueError, match="three taxon names"):
        ServerAction.removeDupTriplets("A B\n")


@pytest.mark.parametrize("weight", ["0.5", "2.0", "two"])
def test_weight_that_is_not_a_whole_number_gives_a_clear_error(weight):
    with pytest.raises(ValueError, match="whole number"):
        ServerAction.removeDupTriplets("A B C " + weight + "\n")


# --- tripletsToNewick (runs Lev1athan.jar) -----------------------------------

# Networks Lev1athan builds from the bundled examples
EXPECTED_NEWICK = {
    "triplets_example1.txt": "((5)#H1,((6,2),((3,4),#H1)));",
    "triplets_example2.txt": "((((3)#H1,4),((1,2),#H1)),5);",
    "triplets_example3_text.txt": "(((((a2,a1))#H1,a4),a5),(a3,#H1));",
    "triplets_example4.txt": "(((3)#H1,(1,2)),((4,5),#H1));",
}


@pytest.mark.java
@pytest.mark.parametrize("filename", sorted(EXPECTED_NEWICK))
def test_example_triplet_files(filename, read_input):
    # triplets_example1.txt contains duplicate triplets, which Lev1athan
    # refuses; tripletsToNewick must remove them first
    newick = ServerAction.tripletsToNewick(read_input(filename))
    assert newick.strip() == EXPECTED_NEWICK[filename]


@pytest.mark.java
def test_weighted_triplets_give_a_tree():
    triplets = "a b c 2\na b d 1\na c d 1\nb c d 1\n"
    assert ServerAction.tripletsToNewick(triplets).strip() == "(((a,b),c),d);"


@pytest.mark.java
def test_works_from_any_folder_and_leaves_no_files(tmp_path, monkeypatch, read_input):
    # Run from an empty working folder, with an empty temp folder
    work_dir, temp_dir = tmp_path / "work", tmp_path / "temp"
    work_dir.mkdir()
    temp_dir.mkdir()
    monkeypatch.chdir(work_dir)
    monkeypatch.setattr(tempfile, "tempdir", str(temp_dir))

    newick = ServerAction.tripletsToNewick(read_input("triplets_example4.txt"))

    assert newick.strip() == EXPECTED_NEWICK["triplets_example4.txt"]
    assert os.listdir(work_dir) == []
    assert os.listdir(temp_dir) == []


@pytest.mark.java
def test_lev1athan_failure_gives_a_clear_error(tmp_path, monkeypatch):
    # A triplet that repeats a name makes Lev1athan stop with an error;
    # its explanation is passed on, and no temporary files are left behind
    monkeypatch.setattr(tempfile, "tempdir", str(tmp_path))
    with pytest.raises(ValueError, match="three DISTINCT"):
        ServerAction.tripletsToNewick("A A B\nA B C\n")
    assert os.listdir(tmp_path) == []


def test_empty_input_gives_a_clear_error():
    with pytest.raises(ValueError, match="No triplets"):
        ServerAction.tripletsToNewick("")


def test_lev1athan_error_message_skips_comments_and_file_names():
    output = ("// COMMENT: Pre-processing showed that there are 3 leaves.\n"
              "Read line: A A B\n"
              "Each line should consist of three DISTINCT integers.\n"
              "Problem reading file /tmp/phyloknit-1234.tmp\n")
    assert ServerAction.lev1athanError(output) == (
        "Read line: A A B Each line should consist of three DISTINCT integers.")
