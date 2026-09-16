# `src` is read-only (typically a flake input in /nix/store); all runtime state
# lives under systemd's StateDirectory instead, and secrets come from `environmentFile`.
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

  # Deliberately NOT setting SystemCallFilter/MemoryDenyWriteExecute/PrivateUsers:
  # weasyprint/psycopg/argon2-cffi are C extensions, same directive class that
  # killed alloy.service (Go) on gcp-relay via an unexpected syscall.
  commonHardening = {
    CapabilityBoundingSet = lib.mkForce "";
    NoNewPrivileges = lib.mkDefault true;
    ProtectSystem = lib.mkDefault "strict";
    ProtectHome = lib.mkDefault true;
    PrivateTmp = lib.mkDefault true;
    PrivateDevices = lib.mkDefault true;
    RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX"];
    ProtectClock = lib.mkDefault true;
    ProtectKernelLogs = lib.mkDefault true;
    ProtectKernelModules = lib.mkDefault true;
    ProtectKernelTunables = lib.mkDefault true;
    ProtectControlGroups = lib.mkDefault true;
    ProtectHostname = lib.mkDefault true;
    RestrictNamespaces = lib.mkDefault true;
    RestrictSUIDSGID = lib.mkDefault true;
    LockPersonality = lib.mkDefault true;
    RestrictRealtime = lib.mkDefault true;
    ProtectProc = lib.mkDefault "invisible";
    ProcSubset = lib.mkDefault "pid";
    UMask = lib.mkDefault "0077";
    RemoveIPC = lib.mkDefault true;
  };

  runScript = pkgs.writeShellScript "job-kombayn-run" ''
    set -euo pipefail
    echo "=== kombayn run: $(date -Is) ==="
    # Profiles are DB-backed: the `profile` metric label set is dynamic (one series
    # per row), so drop stale .prom files first or a removed profile keeps alerting.
    rm -f /var/lib/prometheus-node-exporter-text-files/job_kombayn_*.prom
    "${cfg.pythonPackage}/bin/python3" ${cfg.src}/run.py scan-all ${scriptArgs}
    echo "=== done: $(date -Is) ==="
  '';
in {
  imports = [./k8s-secret.nix];

  options.services.jobKombayn = {
    enable = lib.mkEnableOption "job-kombayn hourly scan";

    src = lib.mkOption {
      type = lib.types.path;
      description = "job-kombayn source tree (run.py, kombayn/, profiles/). Read-only.";
      example = "inputs.jobshunting";
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
        the web frontend, gated by email+password login (kombayn/auth.py;
        users provisioned by hand via `python -m kombayn.auth create-user`,
        not by this module). Reachable via Traefik at
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
      default = pkgs.python3.withPackages (ps: [ps.psycopg ps."psycopg-c" ps.psycopg-pool ps.fastapi ps.uvicorn ps.requests ps.pyjwt ps.argon2-cffi ps.pypdf ps.python-multipart]);
      description = ''
        Python interpreter with psycopg + psycopg-pool + fastapi + uvicorn, for
        job-kombayn-api. Also needs requests: kombayn/__init__.py unconditionally
        imports pipeline -> notify, which imports requests at module load time,
        even though api.py itself never calls into notify. pyjwt + argon2-cffi
        back kombayn/auth.py's JWT-cookie login. pypdf + python-multipart back
        the self-service onboarding routes (kombayn/onboarding.py's PDF
        extraction, api.py's multipart file upload) - see requirements-api.txt
        in job-kombayn, which is the source of truth this package list mirrors.
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
      description = "job-kombayn: scan all DB-backed profiles, notify new vacancies";
      after = ["network-online.target" "postgresql.service"];
      wants = ["network-online.target"];
      path = [cfg.pythonPackage pkgs.bash pkgs.coreutils] ++ lib.optional cfg.useChromium pkgs.chromium;
      environment = lib.mkIf cfg.useChromium {CHROMIUM_BIN = "${pkgs.chromium}/bin/chromium";};
      serviceConfig =
        commonHardening
        // {
          Type = "oneshot";
          User = cfg.user;
          StateDirectory = "job-kombayn";
          WorkingDirectory = "/var/lib/job-kombayn";
          EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
          ExecStart = "${pkgs.bash}/bin/bash ${runScript}";
          Nice = 10;
          IOSchedulingClass = "idle";
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
      environment = {
        KOMBAYN_CORS_ORIGINS = "https://jobko.${config.my.defaults.domain}";
        # WorkingDirectory below is /var/lib/job-kombayn, not cfg.src, so `kombayn`
        # isn't importable via Python's CWD-relative sys.path entry — point at src explicitly.
        PYTHONPATH = cfg.src;
      };
      serviceConfig =
        commonHardening
        // {
          Type = "simple";
          User = cfg.user;
          StateDirectory = "job-kombayn";
          # Must match job-kombayn.service's WorkingDirectory — the scan timer writes
          # Postgres `applications.folder` relative to its own CWD, so a mismatch here
          # 404s every resume.pdf/cover.pdf lookup even though the file exists.
          WorkingDirectory = "/var/lib/job-kombayn";
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
      serviceConfig =
        commonHardening
        // {
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
      serviceConfig =
        commonHardening
        // {
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
