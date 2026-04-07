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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../du4"

usage() {
  cat <<'EOF'
Usage:
  du4 bleach <file>
EOF
}

remove_metadata() {
  command -v exiftool >/dev/null 2>&1 || {
    log stderr "Error: exiftool is required."
    exit 1
  }
  exiftool -all= -overwrite_original "$1" > /dev/null 2>&1
  xattr -c "$1" > /dev/null 2>&1 || true
  log stdout "Bleached."
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -ne 1 ]; then
  usage
  exit 0
fi

[ -f "$1" ] || { log stderr "Error: file '$1' not found."; exit 1; }
remove_metadata "$1"
