# /etc/nixos/services/home-assistant.nix
{ config, pkgs,... }:

{
  services.postgresql.ensureDatabases = [ "homeassistant" ];
  # FIX: Complete the ensureUsers definition
  services.postgresql.ensureUsers = [
    {
      name = "hass";
      ensureDBOwnership = true;
    }
  ];

  services.home-assistant = {
    enable = true;
    extraGroups = [ "dialout" ];
    config = {
      default_config = {};
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };
      recorder = {
        db_url = "postgresql://hass@/homeassistant?host=/run/postgresql";
      };
    };
  };
}