# shellcheck shell=bash
set -euo pipefail

TARGET_DIR="${Lidarr_Album_Path:-${1:-}}"
[[ -z $TARGET_DIR || ! -d $TARGET_DIR || ${Lidarr_EventType:-} == "Test" ]] && exit 0

JF_KEY=$(cat "$JF_API_KEY_FILE")
L_KEY=$(cat "$LIDARR_API_KEY_FILE")

found=0

# FLAC+CUE → split tracks
while IFS= read -r -d "" FLAC; do
  DIR=$(dirname "$FLAC")
  CUE=$(find "$DIR" -maxdepth 1 -name "*.cue" | head -1)
  [[ -z $CUE ]] && continue

  # Skip if already split (more than one flac in dir)
  FLAC_COUNT=$(find "$DIR" -maxdepth 1 -name "*.flac" | wc -l)
  [[ $FLAC_COUNT -gt 1 ]] && continue

  found=1
  TMP_D=$(mktemp -d "$DIR/.split-XXXX")

  if shnsplit -f "$CUE" -o flac -d "$TMP_D" -t "%n - %t" "$FLAC"; then
    cuetag "$CUE" "$TMP_D"/*.flac
    mv "$TMP_D"/*.flac "$DIR/"
    rm "$FLAC"
  fi
  rm -rf "$TMP_D"
done < <(find "$TARGET_DIR" -type f -name "*.flac" -print0)

# APE(+CUE) → FLAC
while IFS= read -r -d "" APE; do
  found=1
  BASE="${APE%.*}"
  [[ -f "$BASE.flac" ]] && continue

  DIR=$(dirname "$APE")
  CUE=$(find "$DIR" -maxdepth 1 -name "*.cue" | head -1)

  if [[ -n $CUE ]]; then
    TMP_D=$(mktemp -d "$DIR/.split-XXXX")
    # -nostdin важен, чтобы ffmpeg не читал из пайпа find
    ffmpeg -nostdin -i "$APE" -c:a flac -y "$TMP_D/f.flac" 2>/dev/null

    if shnsplit -f "$CUE" -o flac -d "$TMP_D" -t "%n - %t" "$TMP_D/f.flac"; then
      cuetag "$CUE" "$TMP_D"/*.flac
      mv "$TMP_D"/*.flac "$DIR/"
      rm "$APE" "$TMP_D/f.flac"
    fi
    rm -rf "$TMP_D"
  else
    ffmpeg -nostdin -i "$APE" -c:a flac -y "$BASE.flac" && rm "$APE"
  fi
done < <(find "$TARGET_DIR" -type f -name "*.ape" -print0)

if [[ $found -eq 1 ]]; then
  # Уведомляем Lidarr о необходимости пересканировать конкретную папку артиста
  curl -sf -X POST -H "X-Api-Key: $L_KEY" -d "{\"name\": \"RescanArtist\", \"path\": \"$(dirname "$TARGET_DIR")\"}" "$LIDARR_URL/api/v1/command" >/dev/null || true
  # Уведомляем Jellyfin
  curl -sf -X POST -H "X-MediaBrowser-Token: $JF_KEY" "$JF_URL/Library/Refresh" >/dev/null || true
fi
