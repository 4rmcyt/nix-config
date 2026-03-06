{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.media-cleaner;

  # Script that processes a single MKV file
  cleanerScript = pkgs.writeShellApplication {
    name = "media-cleaner";
    runtimeInputs = with pkgs; [mkvtoolnix-cli jq curl util-linux];
    text = ''
      set -euo pipefail

      FILE="$1"
      RADARR_URL="${cfg.radarrUrl}"
      SONARR_URL="${cfg.sonarrUrl}"
      RADARR_KEY_FILE="${cfg.radarrApiKeyFile}"
      SONARR_KEY_FILE="${cfg.sonarrApiKeyFile}"
      KEEP_AUDIO_LANGS="${lib.concatStringsSep " " cfg.keepAudioLangs}"
      KEEP_SUB_LANGS="${lib.concatStringsSep " " cfg.keepSubLangs}"

      if [[ ! -f "$FILE" ]]; then
        echo "media-cleaner: file not found: $FILE" >&2
        exit 1
      fi

      # Only process MKV files
      if [[ "''${FILE##*.}" != "mkv" ]]; then
        echo "media-cleaner: skipping non-MKV file: $FILE"
        exit 0
      fi

      RADARR_KEY=$(cat "$RADARR_KEY_FILE")
      SONARR_KEY=$(cat "$SONARR_KEY_FILE")

      FILE_DIR=$(dirname "$FILE")

      # Determine original language via *arr API
      ORIG_LANG=""

      # Try Radarr first (movies)
      if echo "$FILE_DIR" | grep -q "/movies/"; then
        RESPONSE=$(curl -sf \
          -H "X-Api-Key: $RADARR_KEY" \
          "$RADARR_URL/api/v3/movie" 2>/dev/null || true)
        if [[ -n "$RESPONSE" ]]; then
          # Movies: Radarr .path == movie folder (exact match)
          ORIG_LANG=$(echo "$RESPONSE" | jq -r --arg dir "$FILE_DIR" \
            '[.[] | select(.path != null and (.path == $dir or .path == ($dir + "/") or ((.path + "/") as $p | $dir | startswith($p))))] | first | .originalLanguage.name // ""' 2>/dev/null || true)
        fi
      fi

      # Try Sonarr if not found (shows)
      if [[ -z "$ORIG_LANG" ]] && echo "$FILE_DIR" | grep -q "/shows/"; then
        RESPONSE=$(curl -sf \
          -H "X-Api-Key: $SONARR_KEY" \
          "$SONARR_URL/api/v3/series" 2>/dev/null || true)
        if [[ -n "$RESPONSE" ]]; then
          # Shows: Sonarr .path == series root dir, FILE_DIR is season subdir inside it
          ORIG_LANG=$(echo "$RESPONSE" | jq -r --arg dir "$FILE_DIR" \
            '[.[] | select(.path != null and ($dir == .path or ((.path + "/") as $p | $dir | startswith($p))))] | first | .originalLanguage.name // ""' 2>/dev/null || true)
        fi
      fi

      # Map language name (from *arr) to ISO 639-2 tag used by MKVMerge
      lang_to_iso() {
        case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
          english)    echo "eng" ;;
          russian)    echo "rus" ;;
          ukrainian)  echo "ukr" ;;
          hebrew)     echo "heb" ;;
          french)     echo "fra" ;;
          german)     echo "ger" ;;
          spanish)    echo "spa" ;;
          japanese)   echo "jpn" ;;
          chinese)    echo "chi" ;;
          korean)     echo "kor" ;;
          arabic)     echo "ara" ;;
          italian)    echo "ita" ;;
          portuguese) echo "por" ;;
          polish)     echo "pol" ;;
          dutch)      echo "dut" ;;
          turkish)    echo "tur" ;;
          *)          echo "" ;;
        esac
      }

      ORIG_ISO=$(lang_to_iso "$ORIG_LANG")
      echo "media-cleaner: original language='$ORIG_LANG' (iso='$ORIG_ISO') for $FILE"

      # Get track info from file
      TRACK_JSON=$(mkvmerge -J "$FILE")

      # Build list of audio track IDs to keep
      KEEP_AUDIO_IDS=()
      mapfile -t AUDIO_TRACKS < <(echo "$TRACK_JSON" | jq -c '.tracks[] | select(.type == "audio")')
      ALL_AUDIO_COUNT=$(echo "$TRACK_JSON" | jq '[.tracks[] | select(.type == "audio")] | length')

      for TRACK in "''${AUDIO_TRACKS[@]}"; do
        TRACK_ID=$(echo "$TRACK" | jq -r '.id')
        TRACK_LANG=$(echo "$TRACK" | jq -r '.properties.language // "und"')
        TRACK_NAME=$(echo "$TRACK" | jq -r '.properties.track_name // ""' | tr '[:upper:]' '[:lower:]')

        # Skip commentary tracks
        if echo "$TRACK_NAME" | grep -qi "commentary"; then
          echo "media-cleaner: dropping commentary audio track $TRACK_ID (lang=$TRACK_LANG, name=$TRACK_NAME)"
          continue
        fi

        # Keep if language is in the keep list
        KEEP=0
        for LANG in $KEEP_AUDIO_LANGS; do
          if [[ "$TRACK_LANG" == "$LANG" ]]; then
            KEEP=1
            break
          fi
        done

        # Keep if it matches the content's original language
        if [[ -n "$ORIG_ISO" && "$TRACK_LANG" == "$ORIG_ISO" ]]; then
          KEEP=1
        fi

        if [[ "$KEEP" == "1" ]]; then
          KEEP_AUDIO_IDS+=("$TRACK_ID")
        else
          echo "media-cleaner: dropping audio track $TRACK_ID (lang=$TRACK_LANG)"
        fi
      done

      # Build list of subtitle track IDs to keep
      KEEP_SUB_IDS=()
      mapfile -t SUB_TRACKS < <(echo "$TRACK_JSON" | jq -c '.tracks[] | select(.type == "subtitles")')
      ALL_SUB_COUNT=$(echo "$TRACK_JSON" | jq '[.tracks[] | select(.type == "subtitles")] | length')

      for TRACK in "''${SUB_TRACKS[@]}"; do
        TRACK_ID=$(echo "$TRACK" | jq -r '.id')
        TRACK_LANG=$(echo "$TRACK" | jq -r '.properties.language // "und"')

        KEEP=0
        for LANG in $KEEP_SUB_LANGS; do
          if [[ "$TRACK_LANG" == "$LANG" ]]; then
            KEEP=1
            break
          fi
        done

        if [[ "$KEEP" == "1" ]]; then
          KEEP_SUB_IDS+=("$TRACK_ID")
        else
          echo "media-cleaner: dropping subtitle track $TRACK_ID (lang=$TRACK_LANG)"
        fi
      done

      # Check if anything needs to be removed
      if [[ "''${#KEEP_AUDIO_IDS[@]}" -eq "$ALL_AUDIO_COUNT" && "''${#KEEP_SUB_IDS[@]}" -eq "$ALL_SUB_COUNT" ]]; then
        echo "media-cleaner: nothing to remove in $FILE, skipping"
        exit 0
      fi

      # Bail if we'd remove ALL audio tracks (safety check)
      if [[ "''${#KEEP_AUDIO_IDS[@]}" -eq 0 ]]; then
        echo "media-cleaner: WARNING: would remove all audio tracks from $FILE, keeping original" >&2
        exit 0
      fi

      AUDIO_IDS_ARG=$(IFS=,; echo "''${KEEP_AUDIO_IDS[*]}")
      SUB_IDS_ARG=$(IFS=,; echo "''${KEEP_SUB_IDS[*]:-}")
      TMP_FILE="''${FILE}.tmp.mkv"

      echo "media-cleaner: rewriting $FILE (keeping audio: $AUDIO_IDS_ARG, subs: ''${SUB_IDS_ARG:-none})"

      MKVMERGE_ARGS=(-o "$TMP_FILE" --audio-tracks "$AUDIO_IDS_ARG")
      if [[ -n "$SUB_IDS_ARG" ]]; then
        MKVMERGE_ARGS+=(--subtitle-tracks "$SUB_IDS_ARG")
      else
        MKVMERGE_ARGS+=(--no-subtitles)
      fi
      MKVMERGE_ARGS+=("$FILE")

      if ionice -c 3 mkvmerge "''${MKVMERGE_ARGS[@]}"; then
        mv "$TMP_FILE" "$FILE"
        echo "media-cleaner: done $FILE"
      else
        rm -f "$TMP_FILE"
        echo "media-cleaner: ERROR: mkvmerge failed for $FILE" >&2
        exit 1
      fi
    '';
  };

  # Script that scans a directory for all MKVs and processes each one
  scanScript = pkgs.writeShellApplication {
    name = "media-cleaner-scan";
    runtimeInputs = [cleanerScript pkgs.findutils pkgs.coreutils];
    text = ''
      set -euo pipefail
      DIR="$1"
      echo "media-cleaner-scan: scanning $DIR"
      find "$DIR" -type f -name "*.mkv" -print0 | while IFS= read -r -d "" FILE; do
        nice -n 10 media-cleaner "$FILE" || echo "media-cleaner-scan: failed on $FILE, continuing"
      done
      echo "media-cleaner-scan: done $DIR"
    '';
  };
in {
  options.services.media-cleaner = {
    enable = lib.mkEnableOption "MKV track cleaner for movies and shows";

    radarrUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:7878";
      description = "Radarr API base URL";
    };

    sonarrUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:8989";
      description = "Sonarr API base URL";
    };

    radarrApiKeyFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to file containing the Radarr API key (e.g. sops secret path)";
    };

    sonarrApiKeyFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to file containing the Sonarr API key (e.g. sops secret path)";
    };

    moviesDir = lib.mkOption {
      type = lib.types.str;
      default = "/data/media/movies";
      description = "Movies library directory to watch";
    };

    showsDir = lib.mkOption {
      type = lib.types.str;
      default = "/data/media/shows";
      description = "Shows library directory to watch";
    };

    keepAudioLangs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["eng" "und"];
      description = "ISO 639-2 audio language codes to always keep";
    };

    keepSubLangs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["eng" "rus" "heb" "ukr"];
      description = "ISO 639-2 subtitle language codes to keep";
    };
  };

  config = lib.mkIf cfg.enable {
    # Expose the scripts in system packages for manual use
    environment.systemPackages = [cleanerScript scanScript];

    # Sops secrets for API keys (reuse existing recyclarr.yaml)
    sops.secrets.radarr_api_key = {
      sopsFile = ../../../secrets/recyclarr.yaml;
      key = "radarr/movies/api_key";
      owner = config.my.defaults.user;
      mode = "0400";
    };
    sops.secrets.sonarr_api_key = {
      sopsFile = ../../../secrets/recyclarr.yaml;
      key = "sonarr/series/api_key";
      owner = config.my.defaults.user;
      mode = "0400";
    };

    # Path units: trigger scan service when directory contents change
    systemd.paths.media-cleaner-movies = {
      description = "Watch movies dir for new MKV files";
      wantedBy = ["multi-user.target"];
      pathConfig = {
        PathChanged = cfg.moviesDir;
        Unit = "media-cleaner-movies.service";
      };
    };

    systemd.paths.media-cleaner-shows = {
      description = "Watch shows dir for new MKV files";
      wantedBy = ["multi-user.target"];
      pathConfig = {
        PathChanged = cfg.showsDir;
        Unit = "media-cleaner-shows.service";
      };
    };

    # One-shot services that scan the watched directory
    systemd.services.media-cleaner-movies = {
      description = "Clean audio/subtitle tracks in movies library";
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        User = config.my.defaults.user;
        Group = "media";
        ExecStart = "${scanScript}/bin/media-cleaner-scan ${cfg.moviesDir}";
        # Give it time to finish large libraries
        TimeoutStartSec = "6h";
        IOWeight = 50;
        CPUWeight = 50;
        Nice = 10;
      };
    };

    systemd.services.media-cleaner-shows = {
      description = "Clean audio/subtitle tracks in shows library";
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        User = config.my.defaults.user;
        Group = "media";
        ExecStart = "${scanScript}/bin/media-cleaner-scan ${cfg.showsDir}";
        TimeoutStartSec = "6h";
        IOWeight = 50;
        CPUWeight = 50;
        Nice = 10;
      };
    };
  };
}
