# /etc/nixos/services/caddy.nix
{ config, pkgs,... }:

{
  services.caddy = {
    enable = true;
    globalConfig = ''
      email redacted@example.com
    '';
    virtualHosts = {
      "paperless.example.com" = { extraConfig = "reverse_proxy localhost:8082"; };
      "audiobookshelf.example.com" = { extraConfig = "reverse_proxy localhost:8085"; };
      "homeassistant.example.com" = { extraConfig = "reverse_proxy localhost:8123"; };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}