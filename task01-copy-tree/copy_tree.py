#!/usr/bin/env python3
"""
copy_tree.py — Recursively copy a directory tree using only the Python stdlib.
No explicit loops or if-statements in user code.
"""

from argparse import ArgumentParser
from shutil import copytree, ignore_patterns
from pathlib import Path

parser = ArgumentParser(description="Recursively copy a folder (no loops/ifs in user code).")
parser.add_argument("src", help="Source directory path")
parser.add_argument("dest", help="Destination directory path (must not exist)")
parser.add_argument("--quiet", action="store_true", help="Suppress verbose paths in output")
parser.add_argument("--ignore", nargs="*", default=[], help="Glob patterns to ignore, e.g. node_modules *.log")
args = parser.parse_args()

ignore = ignore_patterns(*args.ignore) if args.ignore else None
result = copytree(args.src, args.dest, ignore=ignore)

print("Copy completed." if args.quiet else f"Copied {Path(args.src).resolve()} -> {Path(result).resolve()}")
