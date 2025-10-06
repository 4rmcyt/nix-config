{
  config,
  pkgs,
  lib,
  ...
}:
# This 'let' block defines our data and helper function.
let
  # Step 1: Define a simple list of all the services we want to protect.
  # We only list the parts that are unique to each service.
  servicesToProtect = {
    ssh = {
      filter = "sshd";
      journalmatch = "_SYSTEMD_UNIT=sshd.service";
      maxretry = 3;
      bantime = "1h";
    };
    homeassistant = {
      filter = "homeassistant";
      journalmatch = "_SYSTEMD_UNIT=home-assistant.service";
    };
    keycloak = {
      filter = "keycloak";
      journalmatch = "_SYSTEMD_UNIT=keycloak.service";
      maxretry = 3;
      bantime = "2h";
    };
    jellyfin = {
      filter = "jellyfin";
      journalmatch = "_SYSTEMD_UNIT=jellyfin.service";
      bantime = "30m";
    };
    audiobookshelf = {
      filter = "audiobookshelf";
      journalmatch = "_SYSTEMD_UNIT=audiobookshelf.service";
    };
    paperless = {
      filter = "paperless";
      journalmatch = "_SYSTEMD_UNIT=paperless.service";
    };
    samba = {
      filter = "samba";
      journalmatch = "_SYSTEMD_UNIT=smbd.service";
    };
    radicale = {
      filter = "radicale";
      journalmatch = "_SYSTEMD_UNIT=radicale.service";
    };
    homepage = {
      filter = "homepage";
      journalmatch = "_SYSTEMD_UNIT=homepage.service";
    };
    cloudflared = {
      filter = "cloudflared";
      journalmatch = "_SYSTEMD_UNIT=cloudflared.service";
    };
    miniflux = {
      filter = "miniflux";
      journalmatch = "_SYSTEMD_UNIT=miniflux.service";
    };
    yubikey = {
      filter = "yubikey";
      journalmatch = "_SYSTEMD_UNIT=yubikey.service";
    };
    kavita = {
      filter = "kavita";
      journalmatch = "_SYSTEMD_UNIT=kavita.service";
    };
    transmission = {
      filter = "transmission";
      journalmatch = "_SYSTEMD_UNIT=transmission.service";
    };
    tailscale = {
      filter = "tailscale";
      journalmatch = "_SYSTEMD_UNIT=tailscaled.service";
    };
  };

  # A small helper function to build the jail configuration string.
  mkJailConfig = service: ''
    enabled = true
    backend = systemd
    action = cloudflare-token
    filter = ${service.filter}
    journalmatch = ${service.journalmatch}
    maxretry = ${toString (service.maxretry or config.services.fail2ban.maxretry)}
    bantime = ${service.bantime or "1h"}
    findtime = ${service.findtime or "10m"}
  '';
in {
  # This block was redundant. The 'extraPackages' option below is the correct way.
  # environment.systemPackages = ...;

  sops.secrets = {
    cloudflare_zone_id.sopsFile = ../../../secrets/cloudflare.yaml;
    cloudflare_api_key.sopsFile = ../../../secrets/cloudflare.yaml;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5; # A global default for any jail that doesn't specify its own.

    # These packages are needed for your custom Cloudflare action.
    extraPackages = with pkgs; [
      curl
      jq
    ];

    # Your IP whitelist is correct and should be kept.
    ignoreIP = [
      "127.0.0.0/8"
      "10.0.0.0/8"
      # ... your other IPs
      "131.0.72.0/22"
    ];

    # Step 2: Use a function to generate the entire 'jails' block automatically.
    # lib.mapAttrs iterates over our 'servicesToProtect' list and applies
    # our helper function to each one, creating the final configuration.
    jails = lib.mapAttrs (_name: mkJailConfig) servicesToProtect;
  };

  # Your custom filter and action definitions are excellent and need no changes.
  environment.etc = {
    "fail2ban/filter.d/homeassistant.conf".text = ''
      [Definition]
      failregex = Login attempt or request with invalid authentication from <HOST>
      # ... your other filters
    '';

    "fail2ban/action.d/cloudflare-token.conf".text = let
      notes = "Fail2Ban-${config.networking.hostName}";
      zoneIdFile = config.sops.secrets.cloudflare_zone_id.path;
      apiKeyFile = config.sops.secrets.cloudflare_api_key.path;
    in ''
      [Definition]
      actionban = curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$(cat ${zoneIdFile})/firewall/access_rules/rules" \
          -H "Authorization: Bearer $(cat ${apiKeyFile})" \
          -H "Content-Type: application/json" \
          --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"${notes}"}'

      actionunban = id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$(cat ${zoneIdFile})/firewall/access_rules/rules" \
          -H "Authorization: Bearer $(cat ${apiKeyFile})" \
          -H "Content-Type: application/json" \
          | jq -r '.result[] | select(.notes == "${notes}" and .configuration.value == "<ip>") | .id')
          if [ -z "$id" ]; then exit 0; fi; \
          curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$(cat ${zoneIdFile})/firewall/access_rules/rules/$id" \
              -H "Authorization: Bearer $(cat ${apiKeyFile})"

      [Init]
      name = cloudflare-token
    '';
  };
}
