{
  lib,
  config,
  ...
}: {
  networking.firewall.allowedTCPPorts = lib.mkIf config.services.atuin.openFirewall [config.services.atuin.port];

  services.atuin = {
    enable = true;
    port = 8881;

    database.uri = "postgres://atuin:${config.sops.secrets.atuin.path}@/atuin?host=/run/postgresql";
    openRegistration = true;
  };
}
