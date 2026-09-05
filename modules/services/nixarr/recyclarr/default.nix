{
  config,
  pkgs,
  ...
}: let
  stateDir = "/data/media/.state/nixarr/recyclarr";
in {
  systemd.services.recyclarr-setup = {
    description = "Write Recyclarr environment file";
    before = ["recyclarr.service"];
    requiredBy = ["recyclarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "recyclarr-secrets";
      RuntimeDirectoryMode = "0750";
      User = "recyclarr";
      Group = "recyclarr";
    };
    script = ''
      printf 'RADARR_API_KEY=%s\nSONARR_API_KEY=%s\n' \
        "$(cat ${config.sops.secrets.radarr_api_key.path} | tr -d '\n\r')" \
        "$(cat ${config.sops.secrets.sonarr_api_key.path} | tr -d '\n\r')" \
        > /run/recyclarr-secrets/env
      chmod 600 /run/recyclarr-secrets/env
    '';
  };

  systemd.services.recyclarr = {
    description = "Recyclarr sync";
    after = ["recyclarr-setup.service"];
    requires = ["recyclarr-setup.service"];
    serviceConfig = {
      Type = "oneshot";
      User = "recyclarr";
      Group = "recyclarr";
      EnvironmentFile = "/run/recyclarr-secrets/env";
      Environment = [
        "RECYCLARR_CONFIG_DIR=${stateDir}"
        "RECYCLARR_DATA_DIR=${stateDir}"
      ];
      ExecStart = "${pkgs.recyclarr}/bin/recyclarr sync --config ${../recyclarr.yaml}";
      ReadWritePaths = [stateDir];
    };
  };

  systemd.timers.recyclarr = {
    description = "Recyclarr Timer";
    wantedBy = ["timers.target"];
    partOf = ["recyclarr.service"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 recyclarr recyclarr -"
  ];
}
