# NixOS module: run job-kombayn hourly via a systemd timer.
#
# Usage:
#   services.jobKombayn.enable = true;
#   services.jobKombayn.src = inputs.jobshunting;   # or a local path checkout
#   services.jobKombayn.user = "kombayn";           # default; dedicated system user, peer-auth'd to Postgres
#   services.jobKombayn.environmentFile = config.sops.secrets.job_kombayn_env.path;
#
# `src` is read-only (typically a flake input in /nix/store), so all runtime
# state — dedup index.json, generated resume/cover HTML+PDF, geocode cache —
# lives under systemd's StateDirectory (/var/lib/job-kombayn), not under src.
# Secrets (ANTHROPIC_API_KEY, TELEGRAM_*, ADZUNA_*, RAPIDAPI_KEY, HOME_LAT/LON,
# ...) come from `environmentFile` (an EnvironmentFile) instead of a .env
# sitting next to the script — src has no writable/secret-holding directory.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.jobKombayn;

  scriptArgs = lib.concatStringsSep " " (
    lib.optional cfg.pdf "--pdf" ++ lib.optional cfg.notify "--notify"
  );

  runScript = pkgs.writeShellScript "job-kombayn-run" ''
    set -euo pipefail
    echo "=== kombayn run: $(date -Is) ==="
    ${lib.concatMapStringsSep "\n" (prof: ''
        prof="${cfg.src}/${prof}"
        if [ -f "$prof" ]; then
          echo "--- $prof ---"
          "${cfg.pythonPackage}/bin/python3" ${cfg.src}/run.py scan --profile "$prof" ${scriptArgs} \
            || echo "! scan failed for $prof (continuing)"
        else
          echo "! missing profile: $prof (skip)"
        fi
      '')
      cfg.profiles}
    echo "=== done: $(date -Is) ==="
  '';
in {
  options.services.jobKombayn = {
    enable = lib.mkEnableOption "job-kombayn hourly scan";

    src = lib.mkOption {
      type = lib.types.path;
      description = "job-kombayn source tree (run.py, kombayn/, profiles/). Read-only.";
      example = "inputs.jobshunting";
    };

    profiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "profiles/volodymyr-kondratenko-it.md"
        "profiles/volodymyr-kondratenko-kitchen.md"
        "profiles/volodymyr-kondratenko-survival.md"
        "profiles/sofiia-rogatska-education.md"
        "profiles/sofiia-rogatska-survival.md"
      ];
      description = "Profile files (relative to `src`) to scan each run.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "kombayn";
      description = ''
        User to run the scan as (owns the state directory). Defaults to a
        dedicated `kombayn` system user (created by this module) so Postgres
        peer auth (`local all all peer map=superuser_map` in
        modules/database/postgresql) maps it straight to the `kombayn` DB
        role with no password/secret needed.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        EnvironmentFile with the API keys the scripts read (ANTHROPIC_API_KEY,
        KOMBAYN_MODEL, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, ADZUNA_APP_ID,
        ADZUNA_APP_KEY, RAPIDAPI_KEY, HOME_LAT, HOME_LON, JOOBLE_KEY,
        CAREERJET_KEY, CAREERJET_REFERER, ...). Typically a sops-nix secret
        with `format = "dotenv"`.
      '';
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
      default = pkgs.python3.withPackages (ps: [ps.requests ps.weasyprint ps.psycopg ps."psycopg-c"]);
      description = ''
        Python interpreter with requests + weasyprint (the no-browser PDF engine)
        + psycopg (dedup/status store, kombayn/organize.py — connects to the
        `kombayn` Postgres DB over the local unix socket, peer-auth'd as this
        service's `user`). Add anthropic if you use the paid tailoring path.
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

    enableBot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Run telegram_bot.py as an always-on service (long-polling getUpdates,
        no open port/webhook) that handles the Applied/Skip inline buttons
        notify.send_job attaches to vacancy cards, writing status updates
        straight into the `applications` Postgres table. Needs the same
        TELEGRAM_BOT_TOKEN as the scan timer (from `environmentFile`).
      '';
    };

    enableApi = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Run kombayn/api.py (FastAPI) as an always-on service on
        127.0.0.1:''${toString cfg.apiPort} — read/PATCH-status HTTP API for
        the web frontend. No auth of its own; only reachable via Traefik at
        jobko.''${config.my.defaults.domain}/api or over the tailnet.
      '';
    };

    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 8420;
      description = "Loopback port for the kombayn API service (enableApi).";
    };

    enableWeb = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Serve the built `frontend/` SPA (static-web-server) on
        127.0.0.1:''${toString cfg.webPort}, fronted by Traefik at
        jobko.''${config.my.defaults.domain}.
      '';
    };

    webPort = lib.mkOption {
      type = lib.types.port;
      default = 8421;
      description = "Loopback port for the static frontend (enableWeb).";
    };

    webBuild = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        The built frontend as a Nix package (its output root must contain
        the compiled `dist/`, e.g. via
        `pkgs.buildNpmPackage { src = "''${cfg.src}/frontend"; ... }`).
        Required when enableWeb is true.
      '';
    };

    apiPythonPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3.withPackages (ps: [ps.psycopg ps."psycopg-c" ps.psycopg-pool ps.fastapi ps.uvicorn ps.requests]);
      description = ''
        Python interpreter with psycopg + psycopg-pool + fastapi + uvicorn, for
        job-kombayn-api. Also needs requests: kombayn/__init__.py unconditionally
        imports pipeline -> notify, which imports requests at module load time,
        even though api.py itself never calls into notify.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.kombayn = lib.mkIf (cfg.user == "kombayn") {
      isSystemUser = true;
      group = "kombayn";
    };
    users.groups.kombayn = lib.mkIf (cfg.user == "kombayn") {};

    systemd.services.job-kombayn = {
      description = "job-kombayn: scan all profiles, notify new vacancies";
      path = [cfg.pythonPackage pkgs.bash pkgs.coreutils] ++ lib.optional cfg.useChromium pkgs.chromium;
      environment = lib.mkIf cfg.useChromium {CHROMIUM_BIN = "${pkgs.chromium}/bin/chromium";};
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        StateDirectory = "job-kombayn";
        WorkingDirectory = "/var/lib/job-kombayn";
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = "${pkgs.bash}/bin/bash ${runScript}";
        # be a good citizen on a homeserver
        Nice = 10;
        IOSchedulingClass = "idle";
        # don't let one run pile onto another
        TimeoutStartSec = "20min";
      };
    };

    systemd.timers.job-kombayn = {
      description = "Run job-kombayn (OnCalendar: ${cfg.onCalendar})";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true; # catch up if the box was asleep at the scheduled time
        RandomizedDelaySec = "3min"; # avoid hitting APIs exactly on the hour
      };
    };

    systemd.services.job-kombayn-api = lib.mkIf cfg.enableApi {
      description = "job-kombayn: read/status HTTP API for the web frontend";
      after = ["network-online.target" "postgresql.service"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      path = [cfg.apiPythonPackage];
      environment.KOMBAYN_CORS_ORIGINS = "https://jobko.${config.my.defaults.domain}";
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        StateDirectory = "job-kombayn";
        WorkingDirectory = cfg.src;
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = "${cfg.apiPythonPackage}/bin/uvicorn kombayn.api:app --host 127.0.0.1 --port ${toString cfg.apiPort}";
        Restart = "always";
        RestartSec = "5s";
        Nice = 10;
      };
    };

    systemd.services.job-kombayn-web = lib.mkIf cfg.enableWeb {
      description = "job-kombayn: static frontend (SPA)";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${pkgs.static-web-server}/bin/static-web-server --host 127.0.0.1 --port ${toString cfg.webPort} --root ${cfg.webBuild}/dist";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    systemd.services.job-kombayn-bot = lib.mkIf cfg.enableBot {
      description = "job-kombayn: Telegram Applied/Skip button listener (long-polling)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      path = [cfg.pythonPackage];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        StateDirectory = "job-kombayn"; # shares the .telegram_offset state file
        WorkingDirectory = "/var/lib/job-kombayn";
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = "${cfg.pythonPackage}/bin/python3 ${cfg.src}/telegram_bot.py";
        Restart = "always";
        RestartSec = "10s";
        Nice = 10;
      };
    };
  };
}
