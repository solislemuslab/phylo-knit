"""Tests for the Newick -> DOT converter (ParentheticalConvertorNaman.newickToDot).

The converter names unnamed internal nodes itself ("internal1", ...), so most
tests check the structure of the graph (leaves, and which nodes share a parent)
rather than exact node names.
"""
import re
from collections import defaultdict

import pytest

import ParentheticalConvertorNaman as conv


def edges(dot):
    """Set of (parent, child) edges in a DOT string."""
    return set(re.findall(r"^(\S+) -> (\S+)$", dot, flags=re.MULTILINE))


def children(dot):
    """Map each parent to the set of its children."""
    result = defaultdict(set)
    for parent, child in edges(dot):
        result[parent].add(child)
    return result


def leaves(dot):
    """Nodes that never appear as a parent."""
    es = edges(dot)
    return {c for _, c in es} - {p for p, _ in es}


def test_simple_tree():
    dot = conv.newickToDot("((A,B),C);")
    assert dot.startswith("strict digraph")
    assert leaves(dot) == {"A", "B", "C"}
    assert {"A", "B"} in children(dot).values()
    assert len(edges(dot)) == 4


def test_decimal_branch_lengths_are_removed():
    dot = conv.newickToDot("((A:1.0,B:2.5):0.5,C:3);")
    assert leaves(dot) == {"A", "B", "C"}


def test_named_internal_nodes_keep_their_names():
    # The server names internal nodes "unnamed1", ... before converting;
    # the web page relies on the "internal" prefix to recognise them.
    dot = conv.newickToDot("((A,B)unnamed1,C)unnamed2;")
    assert ("internalunnamed1", "A") in edges(dot)
    assert ("internalunnamed2", "internalunnamed1") in edges(dot)


def test_hybrid_node_has_two_parents():
    # Extended Newick as written by PhyloNetworks (lengths and gammas)
    newick = ("((A:1.0,#H1:1.0::0.4)unnamed1:1.0,"
              "((B:1.0)#H1:1.0::0.6,C:1.0)unnamed2:1.0)unnamed3;")
    dot = conv.newickToDot(newick)
    parents_of_hybrid = {p for p, c in edges(dot) if c == "HashH1"}
    assert parents_of_hybrid == {"internalunnamed1", "internalunnamed2"}
    assert ("HashH1", "B") in edges(dot)
    assert leaves(dot) == {"A", "B", "C"}


def test_repeated_calls_give_the_same_result():
    # The converter keeps module-level state; it must be reset between calls.
    first = conv.newickToDot("((A,B),(C,D));")
    second = conv.newickToDot("((A,B),(C,D));")
    assert first == second


@pytest.mark.xfail(strict=True, reason="known bug: scientific-notation branch "
                   "lengths are not fully removed (leaf 'A' becomes 'Ae-5')")
def test_scientific_notation_branch_lengths_are_removed():
    # PhyloNetworks writes small branch lengths like this
    dot = conv.newickToDot("((A:1.0e-5,B:1.0),C:1.0);")
    assert leaves(dot) == {"A", "B", "C"}


@pytest.mark.xfail(strict=True, reason="known bug: branch lengths without a "
                   "leading zero (':.5') are not removed")
def test_branch_lengths_without_leading_zero_are_removed():
    dot = conv.newickToDot("((A:.5,B:2),C:1);")
    assert leaves(dot) == {"A", "B", "C"}
