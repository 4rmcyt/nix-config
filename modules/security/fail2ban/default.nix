{
  config,
  pkgs,
  lib,
  ...
}:

let

  cloudflare-ips-v4 = pkgs.runCommand "cloudflare-ips-v4" { } ''
    ${pkgs.curl}/bin/curl -s "https://www.cloudflare.com/ips-v4" -o $out
  '';
  cloudflare-ips-v6 = pkgs.runCommand "cloudflare-ips-v6" { } ''
    ${pkgs.curl}/bin/curl -s "https://www.cloudflare.com/ips-v6" -o $out
  '';

  ignoredIPs =
    (lib.splitString "\n" (builtins.readFile cloudflare-ips-v4))
    ++ (lib.splitString "\n" (builtins.readFile cloudflare-ips-v6))
    ++ [
      "127.0.0.0/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];

  jailDefinitions = {
    ssh = {
      unit = "sshd.service";
      maxretry = 3;
      bantime = "1h";
    };
    samba = {
      unit = "smbd.service";
      maxretry = 3;
      bantime = "1h";
    };
    tailscale = {
      unit = "tailscaled.service";
      maxretry = 3;
      bantime = "1h";
    };
  };

  cloudflareAction =
    let
      notes = "Fail2Ban-${config.networking.hostName}";
      # Using lib.escapeShellArg to make the paths safe for shell scripts.
      zoneIdFile = lib.escapeShellArg config.sops.secrets.cloudflare_zone_id.path;
      apiKeyFile = lib.escapeShellArg config.sops.secrets.cloudflare_api_key.path;
      cfapi = "https://api.cloudflare.com/client/v4/zones/$(cat ${zoneIdFile})/firewall/access_rules/rules";
    in
    ''
      [Definition]
      actionstart =
      actionstop =
      actioncheck =

      actionban = ${pkgs.curl}/bin/curl -s -X POST "${cfapi}" \
          -H "Authorization: Bearer $(cat ${apiKeyFile})" \
          -H "Content-Type: application/json" \
          --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"${notes}"}'

      actionunban = id=$(${pkgs.curl}/bin/curl -s -X GET "${cfapi}?notes=${notes}&configuration.target=ip&configuration.value=<ip>" \
          -H "Authorization: Bearer $(cat ${apiKeyFile})" \
          -H "Content-Type: application/json" \
          | ${pkgs.jq}/bin/jq -r 'if .result[0] then .result[0].id else "" end')
          if [ -z "$id" ]; then echo "ID for <ip> not found, skipping unban."; exit 0; fi; \
          ${pkgs.curl}/bin/curl -s -X DELETE "${cfapi}/$id" \
              -H "Authorization: Bearer $(cat ${apiKeyFile})" \
              -H "Content-Type: application/json"

      [Init]
      name = cloudflare-token
    '';

in
{
  sops.secrets = {
    cloudflare_zone_id = {
      sopsFile = ../../secrets/cloudflare.yaml;
      key = "cloudflare_zone_id";
    };
    cloudflare_api_key = {
      sopsFile = ../../secrets/cloudflare.yaml;
      key = "cloudflare_api_key";
    };
  };

  users.users.fail2ban = {
    isSystemUser = true;
    group = "fail2ban";
    description = "Fail2Ban user for banning IPs";
  };
  users.groups.fail2ban = { };
  
  services.fail2ban = {
    enable = true;
    extraPackages = [
      pkgs.curl
      pkgs.jq
    ];
    ignoreIP = ignoredIPs;

    jails = lib.mapAttrs (
      name: jailDef:
      let
        defaults = {
          enabled = true;
          backend = "systemd";
          maxretry = 5;
          findtime = "10m";
          bantime = "1h";
          action = "cloudflare-token";
          filter = name;
        };
        settings = defaults // jailDef;
      in
      {
        inherit (settings)
          enabled
          action
          backend
          maxretry
          findtime
          bantime
          ;
        journalmatch = "_SYSTEMD_UNIT=${settings.unit}";
        filter = settings.filter;
      }
    ) jailDefinitions;
  };
}
