# NixOS module: run job-kombayn hourly via a systemd timer.
#
# Usage: import this from your configuration.nix (or flake), then set:
#   services.jobKombayn.enable = true;
#   services.jobKombayn.projectDir = "/home/zeev/src/job-kombayn";
#   services.jobKombayn.user = "zeev";
#
# Assumes:
#   - a Python env with `requests` (and `anthropic` only if you use the paid path)
#     is available; point pythonPackage at it, or rely on a .venv in projectDir.
#   - <projectDir>/.env holds the keys (ADZUNA_*, RAPIDAPI_KEY, JOOBLE_KEY,
#     CAREERJET_AFFID, TELEGRAM_*, HOME_LAT/HOME_LON). The script loads it.
#   - chromium is installed (for --pdf); this module adds it to PATH.

{ config, lib, pkgs, ... }:

let
  cfg = config.services.jobKombayn;
in {
  options.services.jobKombayn = {
    enable = lib.mkEnableOption "job-kombayn hourly scan";

    projectDir = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the job-kombayn checkout.";
      example = "/home/zeev/src/job-kombayn";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User to run the scan as (needs read/write on projectDir).";
      example = "zeev";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "systemd OnCalendar spec (default: every hour).";
    };

    notify = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Send new vacancies to Telegram each run. Dedup means only NEW postings are
        sent, so steady-state is a trickle. Set false if you want the very first run
        to fill the dedup index quietly (no initial burst), then flip back to true.
      '';
    };

    pdf = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Render resume.pdf + cover_letter.pdf next to the HTML each run.";
    };

    pythonPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3.withPackages (ps: [ ps.requests ps.weasyprint ]);
      description = ''
        Python interpreter with requests + weasyprint (the no-browser PDF engine).
        Add anthropic if you use the paid tailoring path.
      '';
    };

    useChromium = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        If true, also put chromium on the service PATH so PDFs render via the
        browser engine (best fidelity). If false, weasyprint is used (pure Python,
        no browser needed) — simpler on a headless server.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.job-kombayn = {
      description = "job-kombayn: scan all profiles, notify new vacancies";
      # tools the wrapper/script call; chromium only if useChromium is set
      path = [ cfg.pythonPackage pkgs.bash pkgs.coreutils ]
             ++ lib.optional cfg.useChromium pkgs.chromium;
      environment = lib.mkMerge [
        { PYTHON = "${cfg.pythonPackage}/bin/python3";
          KOMBAYN_NOTIFY = if cfg.notify then "1" else "0";
          KOMBAYN_PDF = if cfg.pdf then "1" else "0";
        }
        # let topdf find the browser without guessing (only when chromium is enabled)
        (lib.mkIf cfg.useChromium { CHROMIUM_BIN = "${pkgs.chromium}/bin/chromium"; })
      ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = cfg.projectDir;
        ExecStart = "${pkgs.bash}/bin/bash ${cfg.projectDir}/run_all_profiles.sh";
        # be a good citizen on a homeserver
        Nice = 10;
        IOSchedulingClass = "idle";
        # don't let one run pile onto another
        TimeoutStartSec = "20min";
      };
    };

    systemd.timers.job-kombayn = {
      description = "Run job-kombayn every hour";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;      # catch up if the box was asleep at the scheduled time
        RandomizedDelaySec = "3min";  # avoid hitting APIs exactly on the hour
      };
    };
  };
}
