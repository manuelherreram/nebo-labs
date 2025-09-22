# Task 01 — Copy a directory (no loops/ifs)

## Usage

```bash
./copy_tree.py <src> <dest> [--quiet] [--ignore PATTERN ...]

# Basic usage
./copy_tree.py /tmp/nebo_src /tmp/nebo_dest

# Quiet mode
./copy_tree.py /tmp/nebo_src /tmp/nebo_dest --quiet

# Ignoring specific patterns
./copy_tree.py /tmp/nebo_src /tmp/out --ignore node_modules '*.log'
