#!/bin/bash
# Florent Dufour
# 2016 - 2024

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 pdf compress input.pdf 200
# du4 pdf encrypt -p "p@ssword123" input.pdf
# du4 pdf input.svg # gives output.pdf (with cairo?)
# du4 pdf stamp input.pdf
# du4 pdf embbed outline.ooutline outline.pdf
# du4 pdf extract # pdfdetach -saveall

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------

PDF_DEFAULT_COMPRESS_DPI="300"

# ------------------------------------------------------------------------------
# Code
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../du4"

compress() {
  command -v gs >/dev/null 2>&1 || {
    log stderr "Error: ghostscript (gs) is required for compress."
    exit 1
  }
  gs -dNOPAUSE -dBATCH -dSAFER \
    -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.5 \
    -dPDFSETTINGS=/screen \
    -dEmbedAllFonts=true \
    -dSubsetFonts=true \
    -dColorImageDownsampleType=/Bicubic \
    -dColorImageResolution="$2" \
    -dGrayImageDownsampleType=/Bicubic \
    -dGrayImageResolution="$2" \
    -dMonoImageDownsampleType=/Bicubic \
    -dMonoImageResolution="$2" \
    -sOutputFile="${3:-out.pdf}" \
      "$1"
}

get_fonts() {
  strings "$1" | grep FontName || true
}

extract_img() {
  command -v pdfimages >/dev/null 2>&1 || {
    log stderr "Error: pdfimages is required for extract-img."
    exit 1
  }
  mkdir -p "target"
  pdfimages "$1" "target/in.img"
}

encrypt() {
  local password="$1"
  local in_file="$2"
  local out_file="$3"
  command -v qpdf >/dev/null 2>&1 || {
    log stderr "Error: qpdf is required for encrypt."
    exit 1
  }
  qpdf --encrypt "$password" "$password" 256 -- "$in_file" "$out_file"
}

usage() {
  cat <<'EOF'
Usage:
  du4 pdf compress <input.pdf> [dpi] [output.pdf]
  du4 pdf encrypt -p <password> <input.pdf> [output.pdf]
  du4 pdf extract-img <input.pdf>
  du4 pdf fonts <input.pdf>
EOF
}

subcommand="${1:-}"
if [ -z "$subcommand" ] || [ "$subcommand" = "-h" ] || [ "$subcommand" = "--help" ]; then
  usage
  exit 0
fi
shift || true

case "$subcommand" in
  compress)
    in_file="${1:-}"
    dpi="${2:-$PDF_DEFAULT_COMPRESS_DPI}"
    out_file="${3:-out.pdf}"
    [ -n "$in_file" ] || { usage >&2; exit 1; }
    [ -f "$in_file" ] || { log stderr "Error: file '$in_file' not found."; exit 1; }
    compress "$in_file" "$dpi" "$out_file"
    ;;
  encrypt)
    [ "${1:-}" = "-p" ] || { log stderr "Error: encrypt requires -p <password>."; exit 1; }
    password="${2:-}"
    in_file="${3:-}"
    out_file="${4:-encrypted.pdf}"
    [ -n "$password" ] || { log stderr "Error: empty password."; exit 1; }
    [ -f "$in_file" ] || { log stderr "Error: file '$in_file' not found."; exit 1; }
    encrypt "$password" "$in_file" "$out_file"
    ;;
  extract-img)
    in_file="${1:-}"
    [ -f "$in_file" ] || { log stderr "Error: file '$in_file' not found."; exit 1; }
    extract_img "$in_file"
    ;;
  fonts)
    in_file="${1:-}"
    [ -f "$in_file" ] || { log stderr "Error: file '$in_file' not found."; exit 1; }
    get_fonts "$in_file"
    ;;
  stamp|embed|extract)
    log stderr "Error: subcommand '$subcommand' is not implemented yet."
    exit 1
    ;;
  *)
    log stderr "Error: unknown subcommand '$subcommand'."
    usage >&2
    exit 1
    ;;
esac
