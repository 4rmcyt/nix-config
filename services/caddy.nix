# /etc/nixos/services/caddy.nix
{ config, pkgs,... }:

{
  services.caddy = {
    enable = true;
    globalConfig = ''
      email 4rmcyt@gmail.com
    '';
    virtualHosts = {
      "paperless.labhome.work" = { extraConfig = "reverse_proxy localhost:8082"; };
      "audiobookshelf.labhome.work" = { extraConfig = "reverse_proxy localhost:8085"; };
      "homeassistant.labhome.work" = { extraConfig = "reverse_proxy localhost:8123"; };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}