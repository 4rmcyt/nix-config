{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.ape-converter;

  convertScript = pkgs.writeShellApplication {
    name = "ape-converter";
    runtimeInputs = with pkgs; [ffmpeg-headless coreutils util-linux];
    text = ''
      set -euo pipefail

      FILE="$1"

      if [[ ! -f "$FILE" ]]; then
        echo "ape-converter: file not found: $FILE" >&2
        exit 1
      fi

      # Only process APE files
      if [[ "''${FILE##*.}" != "ape" ]]; then
        echo "ape-converter: skipping non-APE file: $FILE"
        exit 0
      fi

      DEST="''${FILE%.ape}.flac"

      echo "ape-converter: converting $FILE → $DEST"

      if ffmpeg -i "$FILE" -c:a flac -y "$DEST" 2>&1; then
        rm "$FILE"
        echo "ape-converter: done, removed original $FILE"
      else
        rm -f "$DEST"
        echo "ape-converter: ERROR: ffmpeg failed for $FILE" >&2
        exit 1
      fi
    '';
  };

  scanScript = pkgs.writeShellApplication {
    name = "ape-converter-scan";
    runtimeInputs = [convertScript pkgs.findutils pkgs.coreutils pkgs.util-linux];
    text = ''
      set -euo pipefail
      DIR="$1"
      LOCK="''${XDG_RUNTIME_DIR:-/tmp}/ape-converter-scan-$(systemd-escape "$DIR").lock"
      exec 9>"$LOCK"
      if ! flock -n 9; then
        echo "ape-converter-scan: already running for $DIR, skipping"
        exit 0
      fi

      echo "ape-converter-scan: scanning $DIR"
      # Use a temp file to collect paths — avoids pipe subshell issues with set -e
      # and broken reads caused by the pipe closing when a file is deleted mid-stream.
      TMPLIST=$(mktemp)
      trap 'rm -f "$TMPLIST"' EXIT
      find "$DIR" -type f -name "*.ape" -print0 > "$TMPLIST"
      while IFS= read -r -d "" FILE; do
        nice -n 19 ape-converter "$FILE" || echo "ape-converter-scan: failed on $FILE, continuing"
      done < "$TMPLIST"
      echo "ape-converter-scan: done $DIR"
    '';
  };
in {
  options.services.ape-converter = {
    enable = lib.mkEnableOption "APE to FLAC converter for music library";

    musicDir = lib.mkOption {
      type = lib.types.str;
      default = "/data/media/music";
      description = "Music library directory to watch for APE files";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [convertScript scanScript];

    # Timer triggers a scan every 5 minutes.
    # Path units only watch immediate directory entries, not recursive subdirs,
    # so a timer is used instead for music libraries with artist/album/ structure.
    systemd.timers.ape-converter = {
      description = "Periodically scan music dir for APE files";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
        Unit = "ape-converter.service";
      };
    };

    systemd.services.ape-converter = {
      description = "Convert APE files to FLAC in music library";
      after = ["local-fs.target"];
      serviceConfig = {
        Type = "oneshot";
        User = config.my.defaults.user;
        Group = "media";
        ExecStart = "${scanScript}/bin/ape-converter-scan ${cfg.musicDir}";
        TimeoutStartSec = "6h";
        Nice = 19;
        IOWeight = 10;
        CPUWeight = 10;
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
        RuntimeDirectory = "ape-converter";
        Environment = "XDG_RUNTIME_DIR=/run/ape-converter";
      };
    };
  };
}
