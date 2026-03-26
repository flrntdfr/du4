#!/bin/bash
# Florent Dufour
# 2017 - 2022

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 bleach img.jpg    # Remove all metadata from img.jpg
# du4 bleach img.jpg -k # Remove all metadata from img.jpg but keep the original
# du4 bleach file.pdf   # Remove all metadata from file.pdf including recoverable fields

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Code
# ------------------------------------------------------------------------------

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  du4 bleach <file>
EOF
}

remove_metadata() {
  command -v exiftool >/dev/null 2>&1 || {
    echo "Error: exiftool is required." >&2
    exit 1
  }
  exiftool -all= -overwrite_original "$1" > /dev/null 2>&1
  xattr -c "$1" > /dev/null 2>&1 || true
  echo "Bleached."
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -ne 1 ]; then
  usage
  exit 0
fi

[ -f "$1" ] || { echo "Error: file '$1' not found." >&2; exit 1; }
remove_metadata "$1"
