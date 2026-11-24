"""Shared pytest setup for phylo-knit.

The server modules live in src/Server and import each other by plain module
name (e.g. ``import ServerAction``), so that folder is put on sys.path here.
"""
import os
import sys

import pytest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER_DIR = os.path.join(REPO_ROOT, "src", "Server")
INPUT_DIR = os.path.join(REPO_ROOT, "src", "InputFiles")

sys.path.insert(0, SERVER_DIR)


@pytest.fixture
def read_input():
    """Return a function that reads an example file from src/InputFiles."""
    def _read(name):
        with open(os.path.join(INPUT_DIR, name)) as f:
            return f.read()
    return _read
