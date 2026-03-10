# shellcheck shell=bash
set -euo pipefail

TARGET="${BAZARR_MOVIE_FILEPATH:-${BAZARR_EPISODE_FILEPATH:-${Radarr_Movie_File_Path:-${Sonarr_Episode_File_Path:-${1:-}}}}}"

[[ -z $TARGET || ! -f $TARGET || ${TARGET##*.} != "mkv" ]] && exit 0
[[ ${Radarr_EventType:-} == "Test" || ${Sonarr_EventType:-} == "Test" ]] && exit 0

JF_KEY=$(cat "$JF_API_KEY_FILE")
BAZARR_KEY=$(cat "$BAZARR_API_KEY_FILE")
DIR=$(dirname "$TARGET")
BASE_NAME=$(basename "$TARGET" .mkv)

ALLOWED_LANGS=("eng" "rus" "ukr" "heb" "und")

TRACK_JSON=$(mkvmerge -J "$TARGET")

# Helper: check if a language is allowed
is_allowed() {
  local lang="$1"
  for a in "${ALLOWED_LANGS[@]}"; do
    [[ $lang == "$a" ]] && return 0
  done
  return 1
}

REMOVE_ARGS=()

# 1. Find subtitle tracks to remove (not in allowed list)
while IFS= read -r track_id; do
  lang=$(echo "$TRACK_JSON" | jq -r ".tracks[] | select(.id == $track_id) | .properties.language // \"und\"")
  if ! is_allowed "$lang"; then
    REMOVE_ARGS+=("--exclude-track" "$track_id")
  fi
done < <(echo "$TRACK_JSON" | jq -r '.tracks[] | select(.type == "subtitles") | .id')

# 2. Find audio tracks to remove (not in allowed list) — but only if at least one audio track remains
AUDIO_IDS=()
AUDIO_REMOVE=()
while IFS= read -r track_id; do
  lang=$(echo "$TRACK_JSON" | jq -r ".tracks[] | select(.id == $track_id) | .properties.language // \"und\"")
  AUDIO_IDS+=("$track_id")
  if ! is_allowed "$lang"; then
    AUDIO_REMOVE+=("$track_id")
  fi
done < <(echo "$TRACK_JSON" | jq -r '.tracks[] | select(.type == "audio") | .id')

# Safety: only remove audio tracks if at least one would remain
if [[ ${#AUDIO_REMOVE[@]} -gt 0 && ${#AUDIO_REMOVE[@]} -lt ${#AUDIO_IDS[@]} ]]; then
  for track_id in "${AUDIO_REMOVE[@]}"; do
    REMOVE_ARGS+=("--exclude-track" "$track_id")
  done
elif [[ ${#AUDIO_REMOVE[@]} -gt 0 && ${#AUDIO_REMOVE[@]} -eq ${#AUDIO_IDS[@]} ]]; then
  echo "Skipping audio removal: all audio tracks would be removed (no allowed language found)"
fi

# 3. Find external SRTs to embed (only if not already present)
EXT_ARGS=()
SRTS_TO_DELETE=()
while IFS= read -r -d "" SRT; do
  LANG=$(basename "$SRT" | rev | cut -d. -f2 | rev | tr '[:upper:]' '[:lower:]')
  case "$LANG" in
  en | eng) ISO="eng" ;;
  ru | rus) ISO="rus" ;;
  uk | ukr) ISO="ukr" ;;
  he | heb) ISO="heb" ;;
  *) continue ;;
  esac

  if ! echo "$TRACK_JSON" | jq -e ".tracks[] | select(.type == \"subtitles\" and .properties.language == \"$ISO\")" >/dev/null; then
    EXT_ARGS+=("--language" "0:$ISO" "$SRT")
    SRTS_TO_DELETE+=("$SRT")
  fi
done < <(find "$DIR" -maxdepth 1 -name "${BASE_NAME}*.srt" -print0)

# 4. Remux if anything needs to change
if [[ ${#REMOVE_ARGS[@]} -gt 0 || ${#EXT_ARGS[@]} -gt 0 ]]; then
  TMP="$DIR/.tmp.$(basename "$TARGET")"
  if mkvmerge -o "$TMP" "${REMOVE_ARGS[@]}" "$TARGET" "${EXT_ARGS[@]}"; then
    mv "$TMP" "$TARGET"
    [[ ${#SRTS_TO_DELETE[@]} -gt 0 ]] && rm -f "${SRTS_TO_DELETE[@]}"
    curl -sf -X POST -H "X-MediaBrowser-Token: $JF_KEY" "$JF_URL/Library/Refresh" >/dev/null || true
  else
    rm -f "$TMP"
    exit 1
  fi
fi

if [[ -z ${BAZARR_MOVIE_FILEPATH:-} && -z ${BAZARR_EPISODE_FILEPATH:-} ]]; then
  echo "Triggering Bazarr subtitle search..."
  SONARR_ID="${Sonarr_Series_Id:-}"
  if [[ -n "$SONARR_ID" ]]; then
    curl -sf -X PATCH -H "X-Api-Key: $BAZARR_KEY" \
      "$BAZARR_URL/api/series?seriesid=${SONARR_ID}&action=search-missing" >/dev/null || true
  fi
else
  echo "Running under Bazarr. Skipping API callback to prevent loops."
fi
