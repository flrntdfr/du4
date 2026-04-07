#!/bin/bash
# Florent Dufour
# 2026

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 pkill --port 8080 # Kill process using port 8080

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
  du4 pkill --port <port> [--signal <TERM|KILL|...>]

Examples:
  du4 pkill --port 8080
  du4 pkill --port 3000 --signal KILL

Notes:
  - Kills local processes listening on the given TCP port.
  - Uses SIGTERM by default.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log stderr "Error: required command '$1' not found."
    exit 1
  }
}

validate_port() {
  local port="$1"
  if [[ ! "$port" =~ ^[0-9]+$ ]]; then
    log stderr "Error: invalid port '$port'."
    exit 1
  fi
  if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    log stderr "Error: port must be between 1 and 65535."
    exit 1
  fi
}

kill_port() {
  local port="$1"
  local signal="$2"
  local pids

  # Focus on listeners to avoid killing unrelated clients.
  pids="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null | sort -u || true)"
  if [ -z "$pids" ]; then
    log stderr "Error: no process is listening on TCP port '$port'."
    exit 1
  fi

  while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    kill "-$signal" "$pid"
    log stdout "Killed PID $pid on port $port with SIG$signal."
  done <<< "$pids"
}

if [ "${1:-}" = "-v" ] || [ "${1:-}" = "--verbose" ]; then
  du4_set_verbose 1
  shift
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -eq 0 ]; then
  usage
  exit 0
fi

PORT=""
SIGNAL="TERM"

while [ $# -gt 0 ]; do
  case "$1" in
    --port)
      PORT="${2:-}"
      shift
      ;;
    --signal)
      SIGNAL="${2:-}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log stderr "Error: unknown option '$1'."
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ -z "$PORT" ]; then
  log stderr "Error: --port is required."
  usage >&2
  exit 1
fi

if [ -z "$SIGNAL" ]; then
  log stderr "Error: --signal must not be empty."
  exit 1
fi

validate_port "$PORT"
require_cmd lsof
kill_port "$PORT" "$SIGNAL"
