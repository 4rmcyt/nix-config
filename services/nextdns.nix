{ config, pkgs, lib, ... }:
{
  sops.secrets.nextdns_config_id = { };

  services.nextdns = {
    enable = true;
    profile = "nextdns0";
    # You can add other top-level options here if needed
  };

  networking.nameservers = lib.mkForce [ "127.0.0.1" ];
  services.resolved.enable = false;
}