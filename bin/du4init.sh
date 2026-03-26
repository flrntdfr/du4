#!/bin/bash
# Florent Dufour
# 2016 - 2025

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 init tf .               # Init a base terraform project in the current working directory
# du4 init latex              # Init a base latex project in the current working directory
# du4 init brief              # Init a base brief project in the current working directory
# du4 init html               # Init a base html project in the current working directory

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
  du4 init <tf|latex|brief|html> [target-dir]
EOF
}

template="${1:-}"
target="${2:-.}"

if [ -z "$template" ] || [ "$template" = "-h" ] || [ "$template" = "--help" ]; then
  usage
  exit 0
fi

case "$template" in
  tf|latex|brief|html)
    ;;
  *)
    echo "Error: unknown template '$template'." >&2
    usage >&2
    exit 1
    ;;
esac

echo "Template '$template' scaffolding is not implemented yet."
echo "Target directory: $target"
echo "Next step: add template files, then wire copy/generate logic."
exit 1
