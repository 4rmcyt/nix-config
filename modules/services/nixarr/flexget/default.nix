{config, ...}: {
  services.flexget = {
    enable = true;
    inherit (config.my.defaults) user;
    homeDir = "/data/media/.state/nixarr/flexget";
    systemScheduler = true;
    interval = "1h";
    config = ''
      web_server:
        bind: 0.0.0.0
        port: 5050

      schedules:
        - tasks: '*'
          interval:
            hours: 1

      tasks: {}
    '';
  };

  # The upstream module sets WorkingDirectory=/data/... but doesn't wait for the
  # ZFS data pool to be mounted, and doesn't create the homeDir.
  # Override both units to require the mount and pre-create the directory.
  systemd.services.flexget = {
    after = ["data.mount"];
    requires = ["data.mount"];
  };
  systemd.services.flexget-runner = {
    after = ["data.mount"];
    requires = ["data.mount"];
  };

  networking.firewall.allowedTCPPorts = [
    5050 # FlexGet Web UI
  ];

  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/flexget 775 ${config.my.defaults.user} media -"
  ];
}
