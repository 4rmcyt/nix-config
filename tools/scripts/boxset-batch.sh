#!/usr/bin/env bash
# Merge every sub-book in a boxset directory (a folder whose direct children
# are themselves book folders, e.g. "Author - Series (Narrator)/Book 1/*.mp3").
#
# Usage: boxset-batch.sh "<boxset dir>"
set -euo pipefail

BOXSET="${1:?usage: boxset-batch.sh <boxset dir>}"
BACKUP="/mnt/media/media/backup"
SCRIPT_DIR="$(dirname "$0")"

for d in "$BOXSET"/*/; do
  d="${d%/}"
  [ -d "$d" ] || continue
  name=$(basename "$d")
  n=$(find "$d" -maxdepth 1 \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.flac' \) | wc -l)
  if [ "$n" -le 1 ]; then
    echo "SKIP (already merged or no audio): $name"
    continue
  fi
  echo "=== $name ($n files) ==="
  tmp="$d/.tmp_merge.m4b"
  if ! python3 "$SCRIPT_DIR/merge-audiobook.py" "$d" "$tmp" >"$d/merge.log" 2>&1 || [ ! -f "$tmp" ]; then
    echo "FAILED: $name (see $d/merge.log)"
    continue
  fi
  mkdir -p "$BACKUP/$name"
  find "$d" -maxdepth 1 \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.flac' \) -not -name '.*' -exec mv {} "$BACKUP/$name/" \;
  mv "$tmp" "$d/$name.m4b"
  if grep -qiE 'invalid|error|corrupt|missing|overread' "$d/merge.log"; then
    echo "DONE (with decoder warnings, log kept): $name"
  else
    rm -f "$d/merge.log"
    echo "DONE: $name"
  fi
done
echo "ALL_DONE"
