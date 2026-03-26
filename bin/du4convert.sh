#!/usr/bin/env bash
# Florent Dufour
# 2013

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------

# du4 convert *.wav *.mp4               # Convert all wav files to mp4
# du4 convert video.avi video-audio.mp3 # Extract audio from video as mp3
# du4 convert image.png image.ico       # Convert image.png to image.ico

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
  du4 convert <input-file> <output-file>
  du4 convert <glob-pattern> <output-extension>

Examples:
  du4 convert video.avi video-audio.mp3
  du4 convert image.png image.ico
  du4 convert "*.wav" mp4
  
Notes:
  - Converts using stream copy whenever possible (`-c copy`)
  - Falls back to high-quality re-encode only when copy is not possible
EOF
}

to_lower() {
  printf '%s' "${1,,}"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command '$1' not found." >&2
    exit 1
  }
}

is_audio_output_extension() {
  case "$1" in
    mp3|wav|flac|aac|m4a|ogg|oga|opus|aif|aiff)
      return 0
      ;;
  esac
  return 1
}

convert_one() {
  local input="$1"
  local output="$2"
  local out_ext="${output##*.}"
  local -a ffmpeg_copy_args=( )
  local -a ffmpeg_encode_args=( )
  local -a transcode_video_common=( )

  out_ext="$(to_lower "$out_ext")"

  require_cmd ffmpeg

  # Image outputs require actual conversion, not stream copy.
  if [ "$out_ext" = "ico" ]; then
    ffmpeg -hide_banner -loglevel error -y -i "$input" \
      -frames:v 1 \
      -vf "scale=256:256:force_original_aspect_ratio=decrease,pad=256:256:(ow-iw)/2:(oh-ih)/2:color=0x00000000" \
      "$output"
    return 0
  fi

  if is_audio_output_extension "$out_ext"; then
    ffmpeg_copy_args=( -map 0:a:0 -vn -c:a copy )
    case "$out_ext" in
      mp3)
        ffmpeg_encode_args=( -map 0:a:0 -vn -c:a libmp3lame -q:a 0 )
        ;;
      wav|aif|aiff)
        ffmpeg_encode_args=( -map 0:a:0 -vn -c:a pcm_s16le )
        ;;
      flac)
        ffmpeg_encode_args=( -map 0:a:0 -vn -c:a flac -compression_level 12 )
        ;;
      aac|m4a)
        ffmpeg_encode_args=( -map 0:a:0 -vn -c:a aac -b:a 320k )
        ;;
      opus)
        ffmpeg_encode_args=( -map 0:a:0 -vn -c:a libopus -b:a 192k )
        ;;
      ogg|oga)
        ffmpeg_encode_args=( -map 0:a:0 -vn -c:a libvorbis -q:a 8 )
        ;;
      *)
        ffmpeg_encode_args=( -map 0:a:0 -vn -c:a copy )
        ;;
    esac
  else
    ffmpeg_copy_args=( -map 0 -c copy )
    transcode_video_common=(
      -pix_fmt yuv420p
      -movflags +faststart
    )

    case "$out_ext" in
      webm)
        ffmpeg_encode_args=(
          -c:v libvpx-vp9
          -crf 20
          -b:v 0
          -pix_fmt yuv420p
          -c:a libopus
          -b:a 192k
        )
        ;;
      mp4|m4v|mov)
        ffmpeg_encode_args=( -c:v libx264 -crf 18 -preset slow )
        ffmpeg_encode_args+=( "${transcode_video_common[@]}" -c:a aac -b:a 320k )
        ;;
      *)
        ffmpeg_encode_args=( -c:v libx264 -crf 18 -preset slow )
        ffmpeg_encode_args+=( "${transcode_video_common[@]}" -c:a copy )
        ;;
    esac

    ffmpeg_encode_args=( -map 0 "${ffmpeg_encode_args[@]}" )
  fi

  if ffmpeg -hide_banner -loglevel error -y -i "$input" "${ffmpeg_copy_args[@]}" "$output"; then
    return 0
  fi

  ffmpeg -hide_banner -loglevel error -y -i "$input" "${ffmpeg_encode_args[@]}" "$output"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ $# -ne 2 ]; then
  usage >&2
  exit 1
fi

src="$1"
dst="$2"

if [ -e "$src" ]; then
  convert_one "$src" "$dst"
  exit 0
fi

# batch mode: pattern + target extension
if [[ "$dst" == .* ]]; then
  out_ext="${dst#.}"
elif [[ "$dst" == *.* ]]; then
  out_ext="${dst##*.}"
else
  out_ext="$dst"
fi
out_ext="$(to_lower "$out_ext")"

shopt -s nullglob
matches=( $src )
shopt -u nullglob

if [ ${#matches[@]} -eq 0 ]; then
  echo "Error: input '$src' does not exist and pattern matched no files." >&2
  exit 1
fi

require_cmd ffmpeg
for file in "${matches[@]}"; do
  base="${file%.*}"
  output="${base}.${out_ext}"
  convert_one "$file" "$output"
  echo "$output"
done
