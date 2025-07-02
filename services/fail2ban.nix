# /etc/nixos/services/fail2ban.nix
{ config, pkgs, ... }:
{
  services.fail2ban = {
    enable = true;
    jails = {
      DEFAULT = ''
        banaction = cloudflare
        cfuser = ${builtins.readFile config.sops.secrets.cloudflare_email.path}
        cftoken = ${builtins.readFile config.sops.secrets.cloudflare_api_token.path}
      '';
      sshd = ''
        enabled = true
      '';
      nextcloud = ''
        enabled = true
        port = http,https
        logpath = /var/lib/nextcloud/data/nextcloud.log
      '';
    };
  };

  sops.secrets.cloudflare_email = { };
  sops.secrets.cloudflare_api_token = { };
}