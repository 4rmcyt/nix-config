# /etc/nixos/services/radicale.nix
{ config, pkgs,... }:

let
  radicaleHtpasswd = pkgs.writeText "radicale-users" (builtins.readFile config.sops.secrets.radicale_htpasswd.path);
in
{
  # Define the htpasswd content in secrets.yaml
  sops.secrets.radicale_htpasswd = { };

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "127.0.0.1:5232" ]; # Listen locally for Caddy
      auth = {
        type = "htpasswd";
        htpasswd_filename = radicaleHtpasswd;
        htpasswd_encryption = "bcrypt";
      };
    };
  };
}