#!/bin/bash
# Florent Dufour
# 2024

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 posix --perm  <src-file> <dest-file>
# du4 posix --time  <src-file> <dest-file>
# du4 posix --clone <src-file> <dest-file>
# du4 posix --ssh <id_rsa>

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../du4"

# ------------------------------------------------------------------------------
# Code
# ------------------------------------------------------------------------------

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  du4 posix --perm  <src-file> <dest-file>
  du4 posix --time  <src-file> <dest-file>
  du4 posix --clone <src-file> <dest-file>
  du4 posix --ssh   <key-file>

Notes:
  - --perm: best-effort clone of mode, owner/group, ACL/resource metadata, xattrs.
  - --time: best-effort clone of timestamps.
  - --clone: copies file data, then applies both --perm and --time.
  - --ssh: set secure permissions for an SSH key pair (private/public).
  - Metadata preservation depends on platform support and user privileges.
EOF
}

copy_xattrs() {
  local src="$1"
  local dst="$2"
  local attr=""
  local attr_hex=""

  command -v xattr >/dev/null 2>&1 || return 0

  # Remove destination xattrs first so we mirror source as closely as possible.
  xattr -c "$dst" 2>/dev/null || true

  while IFS= read -r attr; do
    [ -n "$attr" ] || continue
    attr_hex="$(xattr -px "$attr" "$src" 2>/dev/null || true)"
    [ -n "$attr_hex" ] || continue
    xattr -wx "$attr" "$attr_hex" "$dst" 2>/dev/null || true
  done < <(xattr "$src" 2>/dev/null || true)
}

validate_source_target() {
  local src_file="$1"
  local dest_file="$2"

  if [ ! -e "$src_file" ]; then
    log stderr "Error: source '$src_file' not found."
    exit 1
  fi
  if [ ! -e "$dest_file" ]; then
    log stderr "Error: destination '$dest_file' not found."
    exit 1
  fi
  if [ -d "$src_file" ]; then
    log stderr "Error: source '$src_file' is a directory; expected a file."
    exit 1
  fi
  if [ -d "$dest_file" ]; then
    log stderr "Error: destination '$dest_file' is a directory; expected a file."
    exit 1
  fi
}

clone_perm() {
  local src_file="$1"
  local dest_file="$2"
  local mode=""
  local owner_group=""

  validate_source_target "$src_file" "$dest_file"

  # Best-effort mode clone. Works on GNU and BSD/macOS (fallback).
  if chmod --reference="$src_file" "$dest_file" 2>/dev/null; then
    :
  else
    mode="$(stat -f '%Lp' "$src_file" 2>/dev/null || true)"
    if [ -n "$mode" ]; then
      chmod "$mode" "$dest_file" 2>/dev/null || true
    fi
  fi

  # Best-effort owner/group clone. May fail for unprivileged users.
  if chown --reference="$src_file" "$dest_file" 2>/dev/null; then
    :
  else
    owner_group="$(stat -f '%Su:%Sg' "$src_file" 2>/dev/null || true)"
    if [ -n "$owner_group" ]; then
      chown "$owner_group" "$dest_file" 2>/dev/null || true
    fi
  fi

  # Explicit xattr mirror to improve fidelity.
  if [ ! -L "$src_file" ] && [ ! -L "$dest_file" ]; then
    copy_xattrs "$src_file" "$dest_file"
  fi

  log stdout "Permissions/ownership metadata cloned from '$src_file' to '$dest_file'."
}

clone_time() {
  local src_file="$1"
  local dest_file="$2"

  validate_source_target "$src_file" "$dest_file"
  touch -r "$src_file" "$dest_file" 2>/dev/null || true
  log stdout "Timestamps cloned from '$src_file' to '$dest_file'."
}

clone_file() {
  local src_file="$1"
  local dest_file="$2"
  local link_target=""

  if [ ! -e "$src_file" ]; then
    log stderr "Error: source '$src_file' not found."
    exit 1
  fi
  if [ -d "$src_file" ]; then
    log stderr "Error: source '$src_file' is a directory; expected a file."
    exit 1
  fi

  # Copy data first.
  if [ -L "$src_file" ]; then
    link_target="$(readlink "$src_file")"
    rm -f "$dest_file"
    ln -s "$link_target" "$dest_file"
  else
    cp -f "$src_file" "$dest_file"
  fi

  # Then apply both metadata groups.
  clone_perm "$src_file" "$dest_file"
  clone_time "$src_file" "$dest_file"
  log stdout "Cloned '$src_file' to '$dest_file' (--perm + --time)."
}

set_ssh_perms() {
  local key_file="$1"
  local private_key=""
  local public_key=""

  if [ ! -e "$key_file" ]; then
    log stderr "Error: key file '$key_file' not found."
    exit 1
  fi
  if [ -d "$key_file" ]; then
    log stderr "Error: key file '$key_file' is a directory; expected a file."
    exit 1
  fi

  if [[ "$key_file" == *.pub ]]; then
    public_key="$key_file"
    private_key="${key_file%.pub}"
  else
    private_key="$key_file"
    public_key="${key_file}.pub"
  fi

  if [ -e "$private_key" ] && [ ! -d "$private_key" ]; then
    chmod 600 "$private_key"
  fi
  if [ -e "$public_key" ] && [ ! -d "$public_key" ]; then
    chmod 644 "$public_key"
  fi

  if [ ! -e "$private_key" ] && [ ! -e "$public_key" ]; then
    log stderr "Error: could not find matching SSH key pair for '$key_file'."
    exit 1
  fi

  log stdout "SSH key permissions set (private: 600, public: 644)."
}

if [ "${1:-}" = "-v" ] || [ "${1:-}" = "--verbose" ]; then
  du4_set_verbose 1
  shift
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -eq 0 ]; then
  usage
  exit 0
fi

case "$1" in
  --perm)
    [ $# -eq 3 ] || { usage >&2; exit 1; }
    clone_perm "$2" "$3"
    ;;
  --time)
    [ $# -eq 3 ] || { usage >&2; exit 1; }
    clone_time "$2" "$3"
    ;;
  --clone)
    [ $# -eq 3 ] || { usage >&2; exit 1; }
    clone_file "$2" "$3"
    ;;
  --ssh)
    [ $# -eq 2 ] || { usage >&2; exit 1; }
    set_ssh_perms "$2"
    ;;
  *)
    log stderr "Error: unknown option '$1'."
    usage >&2
    exit 1
    ;;
esac
