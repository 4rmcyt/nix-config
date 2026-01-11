{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.services.vdirsyncer;
in {
  options.my.services.vdirsyncer = {
    enable = lib.mkEnableOption "vdirsyncer calendar and contacts synchronization";

    package = lib.mkPackageOption pkgs "vdirsyncer" {};

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5";
      description = ''
        How often to run vdirsyncer (systemd timer format).
        Default is every 5 minutes.
      '';
    };

    verbosity = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "CRITICAL"
          "ERROR"
          "WARNING"
          "INFO"
          "DEBUG"
        ]
      );
      default = null;
      description = "Verbosity level for vdirsyncer output.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional configuration file path.
        If not specified, uses $XDG_CONFIG_HOME/vdirsyncer/config
      '';
    };

    calendarsPath = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.calendars";
      description = "Path where calendar files will be stored locally.";
    };

    pairs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          a = lib.mkOption {
            type = lib.types.str;
            description = "Name of the first storage (usually local).";
          };
          b = lib.mkOption {
            type = lib.types.str;
            description = "Name of the second storage (usually remote).";
          };
          collections = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "List of collections to sync. null means discover all.";
          };
          conflictResolution = lib.mkOption {
            type = lib.types.enum ["a wins" "b wins"];
            default = "b wins";
            description = "How to resolve conflicts.";
          };
        };
      });
      default = {};
      description = "Pair definitions for synchronization.";
    };

    storages = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          type = lib.mkOption {
            type = lib.types.str;
            description = "Storage type (e.g., 'filesystem', 'caldav', 'google_calendar').";
          };
          fileext = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "File extension for filesystem storage.";
          };
          path = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Path for filesystem storage.";
          };
          url = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "URL for remote storages.";
          };
          tokenFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to token file for OAuth authentication.";
          };
          clientIdCommand = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Command to retrieve client ID.";
          };
          clientSecretCommand = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Command to retrieve client secret.";
          };
          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Additional storage-specific configuration.";
          };
        };
      });
      default = {};
      description = "Storage definitions.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile."vdirsyncer/config" = lib.mkIf (cfg.configFile == null && (cfg.pairs != {} || cfg.storages != {})) {
      text = let
        mkPair = name: pair: ''
          [pair ${name}]
          a = "${pair.a}"
          b = "${pair.b}"
          ${lib.optionalString (pair.collections != null) "collections = ${builtins.toJSON pair.collections}"}
          conflict_resolution = "${pair.conflictResolution}"
        '';

        mkStorage = name: storage: ''
          [storage ${name}]
          type = "${storage.type}"
          ${lib.optionalString (storage.fileext != null) "fileext = \"${storage.fileext}\""}
          ${lib.optionalString (storage.path != null) "path = \"${storage.path}\""}
          ${lib.optionalString (storage.url != null) "url = \"${storage.url}\""}
          ${lib.optionalString (storage.tokenFile != null) "token_file = \"${storage.tokenFile}\""}
          ${lib.optionalString (storage.clientIdCommand != null) "client_id.fetch = [\"command\", ${builtins.toJSON (lib.splitString " " storage.clientIdCommand)}]"}
          ${lib.optionalString (storage.clientSecretCommand != null) "client_secret.fetch = [\"command\", ${builtins.toJSON (lib.splitString " " storage.clientSecretCommand)}]"}
          ${storage.extraConfig}
        '';
      in ''
        [general]
        status_path = "${cfg.calendarsPath}/status"

        ${lib.concatStringsSep "\n\n" (lib.mapAttrsToList mkPair cfg.pairs)}

        ${lib.concatStringsSep "\n\n" (lib.mapAttrsToList mkStorage cfg.storages)}
      '';
    };

    systemd.user.services.vdirsyncer = {
      Unit = {
        Description = "vdirsyncer calendar & contacts synchronization";
        After = ["network-online.target"];
      };

      Service = let
        vdirsyncerCmd = "${cfg.package}/bin/vdirsyncer";
        verbosityFlag = lib.optionalString (cfg.verbosity != null) "--verbosity ${cfg.verbosity}";
        configFlag = lib.optionalString (cfg.configFile != null) "--config ${cfg.configFile}";
      in {
        Type = "oneshot";
        ExecStart = [
          "${vdirsyncerCmd} ${verbosityFlag} ${configFlag} discover"
          "${vdirsyncerCmd} ${verbosityFlag} ${configFlag} sync"
        ];
      };
    };

    systemd.user.timers.vdirsyncer = {
      Unit = {
        Description = "vdirsyncer synchronization timer";
      };

      Timer = {
        OnCalendar = cfg.frequency;
        Persistent = true;
      };

      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
