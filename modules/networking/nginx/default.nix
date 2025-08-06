{ config, pkgs, ... }:
{
  users.users.nginx = {
    isSystemUser = true;
    group = "acme";
    extraGroups = [
      "users"
      "acme"
    ];
  };
  users.groups.nginx = { };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

  services.nginx = {
    enable = true;
    group = "nginx";
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    statusPage = true;
  };
}
