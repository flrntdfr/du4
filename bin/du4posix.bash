#!/bin/bash
# Florent Dufour
# 2024

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 posix --clone-perm <from-file> <to-file>

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
  du4 posix --clone-perm <from-file> <to-file>
EOF
}

clone_perm() {
  local from_file="$1"
  local to_file="$2"

  [ -e "$from_file" ] || { echo "Error: source '$from_file' not found." >&2; exit 1; }
  [ -e "$to_file" ] || { echo "Error: target '$to_file' not found." >&2; exit 1; }

  if chmod --reference="$from_file" "$to_file" 2>/dev/null; then
    :
  else
    mode="$(stat -f '%Lp' "$from_file" 2>/dev/null || true)"
    [ -n "${mode:-}" ] || { echo "Error: could not read mode from '$from_file'." >&2; exit 1; }
    chmod "$mode" "$to_file"
  fi

  # Preserve owner/group when allowed; do not fail hard if unprivileged.
  if chown --reference="$from_file" "$to_file" 2>/dev/null; then
    :
  else
    owner_group="$(stat -f '%Su:%Sg' "$from_file" 2>/dev/null || true)"
    if [ -n "${owner_group:-}" ]; then
      chown "$owner_group" "$to_file" 2>/dev/null || true
    fi
  fi

  echo "Permissions cloned from '$from_file' to '$to_file'."
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -eq 0 ]; then
  usage
  exit 0
fi

case "$1" in
  --clone-perm)
    [ $# -eq 3 ] || { usage >&2; exit 1; }
    clone_perm "$2" "$3"
    ;;
  *)
    echo "Error: unknown option '$1'." >&2
    usage >&2
    exit 1
    ;;
esac
