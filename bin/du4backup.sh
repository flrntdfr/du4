#!/bin/bash
# Florent Dufour
# 2016 - 2025

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 backup <folder>             # Backup folder in $BACKUP_DEFAULT_LOCATION
# du4 backup <file>               # Backup file in $BACKUP_DEFAULT_LOCATION
# du4 backup <folder> .           # folder.<timestamp>.bkup in the current directory
# du4 backup <folder> /mnt/backup # backup in /mnt/backup
# du4 backup <folder> /mnt/backup --engine=txz # backup in /mnt/backup using txz
# du4 backup <folder> /mnt/backup --engine=aa # backup in /mnt/backup using Apple Archive `aa`

# ------------------------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------------------------

BACKUP_DEFAULT_LOCATION="~/Documents/backups"
BACKUP_ENGINE="aa" # tar, txz, aa, zip

# ------------------------------------------------------------------------------
# CODE
# ------------------------------------------------------------------------------

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  du4 backup <source> [destination] [--engine=tar|txz|aa|zip]
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command '$1' is not installed." >&2
    exit 1
  }
}

SOURCE="${1:-}"
if [ -z "$SOURCE" ]; then
  usage >&2
  exit 1
fi
shift || true

DESTINATION="$BACKUP_DEFAULT_LOCATION"
ENGINE="$BACKUP_ENGINE"

if [ "${1:-}" != "" ] && [[ "${1:-}" != --* ]]; then
  DESTINATION="$1"
  shift || true
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --engine=*)
      ENGINE="${1#--engine=}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option '$1'." >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ ! -e "$SOURCE" ]; then
  echo "Error: source '$SOURCE' does not exist." >&2
  exit 1
fi

if [ "$DESTINATION" = "." ]; then
  DESTINATION="$(pwd)"
fi
DESTINATION="${DESTINATION/#\~/$HOME}"
mkdir -p "$DESTINATION"

case "$ENGINE" in
  tar|txz|zip|aa|aar)
    :
    ;;
  *)
    echo "Error: unsupported engine '$ENGINE'. Use tar, txz, aa, or zip." >&2
    exit 1
    ;;
esac

source_base="$(basename "$SOURCE")"
timestamp="$(date +%Y%m%d-%H%M%S)"
archive_name="${source_base}.${timestamp}.bkup"
archive_path="$DESTINATION/$archive_name"

case "$ENGINE" in
  tar)
    require_cmd tar
    tar -cf "$archive_path" -C "$(dirname "$SOURCE")" "$source_base"
    ;;
  txz)
    require_cmd tar
    tar -cJf "$archive_path" -C "$(dirname "$SOURCE")" "$source_base"
    ;;
  zip)
    require_cmd zip
    (
      cd "$(dirname "$SOURCE")"
      zip -r "$archive_path" "$source_base" >/dev/null
    )
    ;;
  aa|aar)
    require_cmd aa
    (
      if [ -d "$SOURCE" ]; then
        aa archive -d "$SOURCE" -o "$archive_path"
      else
        aa archive -i "$SOURCE" -o "$archive_path"
      fi
    )
    ;;
  *)
    echo "Error: unsupported engine '$ENGINE'. Use tar, txz, aa, or zip." >&2
    exit 1
    ;;
esac

echo "$archive_path"
