#!/usr/bin/env bash
DT="/mnt/media/media/audiobooks/Стивен Кинг - Темная Башня 0-7 (Роман Волков и др.)"
BACKUP="/mnt/media/media/backup"
for d in "$DT"/Тёмная*; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  n=$(find "$d" -maxdepth 1 \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.flac' \) | wc -l)
  [ "$n" -le 1 ] && { echo "SKIP (already merged): $name"; continue; }
  echo "=== $name ($n files) ==="
  tmp="$d/.tmp_merge.m4b"
  python3 /home/zeev/src/nix-config/tools/scripts/merge-audiobook.py "$d" "$tmp" > "$d/merge.log" 2>&1
  if [ $? -ne 0 ] || [ ! -f "$tmp" ]; then
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
