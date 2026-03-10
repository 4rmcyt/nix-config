# shellcheck shell=bash
set -euo pipefail

TARGET="${BAZARR_MOVIE_FILEPATH:-${BAZARR_EPISODE_FILEPATH:-${Radarr_Movie_File_Path:-${Sonarr_Episode_File_Path:-${1:-}}}}}"

[[ -z "$TARGET" || ! -f "$TARGET" || "${TARGET##*.}" != "mkv" ]] && exit 0
[[ "${Radarr_EventType:-}" == "Test" || "${Sonarr_EventType:-}" == "Test" ]] && exit 0

JF_KEY=$(cat "$JF_API_KEY_FILE")
DIR=$(dirname "$TARGET")
BASE_NAME=$(basename "$TARGET" .mkv)

TRACK_JSON=$(mkvmerge -J "$TARGET")
EXT_ARGS=()
SRTS_TO_DELETE=()

while IFS= read -r -d "" SRT; do
  LANG=$(basename "$SRT" | rev | cut -d. -f2 | rev | tr '[:upper:]' '[:lower:]')
  case "$LANG" in
    en|eng) ISO="eng" ;;
    ru|rus) ISO="rus" ;;
    uk|ukr) ISO="ukr" ;;
    he|heb) ISO="heb" ;;
    *) continue ;;
  esac

  if ! echo "$TRACK_JSON" | jq -e ".tracks[] | select(.type == \"subtitles\" and .properties.language == \"$ISO\")" >/dev/null; then
    EXT_ARGS+=("--language" "0:$ISO" "$SRT")
    SRTS_TO_DELETE+=("$SRT")
  fi
done < <(find "$DIR" -maxdepth 1 -name "${BASE_NAME}*.srt" -print0)

if [[ ${#EXT_ARGS[@]} -gt 0 ]]; then
  TMP="$DIR/.tmp.$(basename "$TARGET")"
  if mkvmerge -o "$TMP" "$TARGET" "${EXT_ARGS[@]}"; then
    mv "$TMP" "$TARGET"
    rm -f "${SRTS_TO_DELETE[@]}"
    curl -sf -X POST -H "X-MediaBrowser-Token: $JF_KEY" "$JF_URL/Library/Refresh" >/dev/null || true
  else
    rm -f "$TMP"
    exit 1
  fi
fi
