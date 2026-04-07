#!/usr/bin/bash
# Florent Dufour

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 now /tmp      # Set /tmp to be the now directory
# du4 now           # Change directory to now
# du4 now 1 ~/.ssh  # Set now1
# du4 now 1         # Go to now1 (~/.ssh)
# du4 now --print   # Print all registers
# du4 now --prune   # Delete broken registers
# du4 now --finder  # Open now folder in Finder

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------

# BEGIN_DU4NOW_STATE
NOW_DEFAULT=""
NOW_SLOT_1=""
NOW_SLOT_2=""
NOW_SLOT_3=""
NOW_SLOT_4=""
NOW_SLOT_5=""
NOW_SLOT_6=""
NOW_SLOT_7=""
NOW_SLOT_8=""
NOW_SLOT_9=""
# END_DU4NOW_STATE

# ------------------------------------------------------------------------------
# Code
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../du4"

SCRIPT_PATH="${BASH_SOURCE[0]}"

usage() {
  cat <<'USAGE'
Usage:
  du4 now [path]
  du4 now <slot 1-9> [path]
  du4 now --print
  du4 now --prune
  du4 now --before
  du4 now --finder
  du4 now --version

Notes:
  - Directory switch is emitted as shell code; use: eval "$(du4 now ...)"
USAGE
}

quote_shell() {
  printf '%q' "$1"
}

set_state_var() {
  local key="$1"
  local value="$2"
  local escaped pattern
  escaped="$(printf '%s' "$value" | sed -e 's/[\\/&]/\\&/g')"
  pattern="^${key}=\\\".*\\\"$"
  sed -i.bak -E "s|$pattern|${key}=\"${escaped}\"|" "$SCRIPT_PATH"
  rm -f "${SCRIPT_PATH}.bak"
}

read_slot() {
  local slot="$1"
  local key="NOW_SLOT_${slot}"
  eval "printf '%s' \"\${$key}\""
}

set_slot() {
  local slot="$1"
  local path="$2"
  [ -d "$path" ] || { log stderr "Error: directory '$path' not found."; exit 1; }
  path="$(cd "$path" && pwd)"
  set_state_var "NOW_SLOT_${slot}" "$path"
  echo "Set now$slot=$path"
}

set_default() {
  local path="$1"
  [ -d "$path" ] || { log stderr "Error: directory '$path' not found."; exit 1; }
  path="$(cd "$path" && pwd)"
  set_state_var NOW_DEFAULT "$path"
  echo "Set now=$path"
}

emit_cd() {
  local path="$1"
  [ -n "$path" ] || { log stderr "Error: no path configured."; exit 1; }
  [ -d "$path" ] || { log stderr "Error: configured path '$path' does not exist. Run --prune."; exit 1; }
  echo "cd $(quote_shell "$path")"
}

open_now_in_finder() {
  local path="$1"
  [ -n "$path" ] || { log stderr "Error: no path configured."; exit 1; }
  [ -d "$path" ] || { log stderr "Error: configured path '$path' does not exist. Run --prune."; exit 1; }
  command -v open >/dev/null 2>&1 || {
    log stderr "Error: 'open' command not found; cannot launch Finder."
    exit 1
  }
  open -a Finder "$path"
}

print_state() {
  echo "now=$NOW_DEFAULT"
  echo "now1=$NOW_SLOT_1"
  echo "now2=$NOW_SLOT_2"
  echo "now3=$NOW_SLOT_3"
  echo "now4=$NOW_SLOT_4"
  echo "now5=$NOW_SLOT_5"
  echo "now6=$NOW_SLOT_6"
  echo "now7=$NOW_SLOT_7"
  echo "now8=$NOW_SLOT_8"
  echo "now9=$NOW_SLOT_9"
}

prune_state() {
  local key value updated=false
  for key in NOW_DEFAULT NOW_SLOT_1 NOW_SLOT_2 NOW_SLOT_3 NOW_SLOT_4 NOW_SLOT_5 NOW_SLOT_6 NOW_SLOT_7 NOW_SLOT_8 NOW_SLOT_9; do
    eval "value=\"\${$key}\""
    if [ -n "$value" ] && [ ! -d "$value" ]; then
      set_state_var "$key" ""
      echo "Pruned $key=$value"
      updated=true
    fi
  done
  if [ "$updated" = "false" ]; then
    echo "Nothing to prune."
  fi
}

if [ $# -eq 0 ]; then
  emit_cd "$NOW_DEFAULT"
  exit 0
fi

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  --print)
    print_state
    exit 0
    ;;
  --prune)
    prune_state
    exit 0
    ;;
  --finder)
    open_now_in_finder "$NOW_DEFAULT"
    exit 0
    ;;
  --before)
    echo "cd -"
    exit 0
    ;;
  --version)
    echo "du4 now v0.1.0"
    exit 0
    ;;
esac

if [[ "${1:-}" =~ ^[1-9]$ ]]; then
  slot="$1"
  if [ $# -eq 1 ]; then
    emit_cd "$(read_slot "$slot")"
    exit 0
  fi
  if [ $# -eq 2 ]; then
    set_slot "$slot" "$2"
    exit 0
  fi
  usage >&2
  exit 1
fi

if [ $# -eq 1 ]; then
  set_default "$1"
  exit 0
fi

usage >&2
exit 1
