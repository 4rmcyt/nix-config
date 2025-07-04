{ config, pkgs, ... }:

{
  # SOPS secrets for Cloudflare API
  sops.secrets.cloudflare_api_key = { };
  sops.secrets.cloudflare_zone_id = { };

  services.fail2ban = {
    enable = true;
    maxretry = 5;

    extraPackages = [ pkgs.curl pkgs.jq ];

    ignoreIP = [
      "127.0.0.0/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      # Add Cloudflare IPs here if you want to never ban them locally
    ];

    jails = {
  ssh = {
    settings = {
      enabled = true;
      filter = "sshd";
      logpath = "/var/log/auth.log";
      maxretry = 3;
      bantime = "1h";
      findtime = "10m";
      action = "cloudflare-token";
    };
  };

  nextcloud = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=nextcloud-phpfpm.service";
      filter = "nextcloud";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  homeassistant = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=home-assistant.service";
      filter = "homeassistant";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  keycloak = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=keycloak.service";
      filter = "keycloak";
      maxretry = 3;
      findtime = "10m";
      bantime = "2h";
      action = "cloudflare-token";
    };
  };

  jellyfin = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=jellyfin.service";
      filter = "jellyfin";
      maxretry = 5;
      findtime = "10m";
      bantime = "30m";
      action = "cloudflare-token";
    };
  };

  audiobookshelf = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=audiobookshelf.service";
      filter = "audiobookshelf";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  microbin = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=microbin.service";
      filter = "microbin";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  paperless = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=paperless.service";
      filter = "paperless";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  samba = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=smbd.service";
      filter = "samba";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  radicale = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=radicale.service";
      filter = "radicale";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  caddy = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=caddy.service";
      filter = "caddy";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  delugevpn = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=deluge-vpn.service";
      filter = "delugevpn";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  homepage = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=homepage.service";
      filter = "homepage";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  tailscale = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=tailscaled.service";
      filter = "tailscale";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  cloudflared = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=cloudflared.service";
      filter = "cloudflared";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  media-content = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=media-content.service";
      filter = "media-content";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };

  yubikey = {
    settings = {
      enabled = true;
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=yubikey.service";
      filter = "yubikey";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      action = "cloudflare-token";
    };
  };
};

  # Custom filters for each service
  environment.etc = {
    "fail2ban/filter.d/homeassistant.conf".text = ''
      [Definition]
      failregex = Login attempt or request with invalid authentication from <HOST>
                  Invalid authentication.*from <HOST>
      ignoreregex =
    '';

    "fail2ban/filter.d/nextcloud.conf".text = ''
      [Definition]
      failregex = Login failed:.*remoteAddr:<HOST>
                  Brute force attempt.*remoteAddr:<HOST>
                  Invalid credentials.*remoteAddr:<HOST>
      ignoreregex =
    '';

    "fail2ban/filter.d/keycloak.conf".text = ''
      [Definition]
      failregex = type=LOGIN_ERROR.*realmId=.*clientId=.*userId=.*ipAddress=<HOST>
                  Invalid user credentials.*clientIP=<HOST>
      ignoreregex =
    '';

    "fail2ban/filter.d/jellyfin.conf".text = ''
      [Definition]
      failregex = Authentication request for .* has been denied \(IP: <HOST>\)
                  Invalid login attempt.*IP:<HOST>
      ignoreregex =
    '';

    # Cloudflare action configuration
    "fail2ban/action.d/cloudflare-token.conf".text =
      let
        notes = "Fail2Ban-${config.networking.hostName}";
        cfapi = "https://api.cloudflare.com/client/v4/zones/$(cat ${config.sops.secrets.cloudflare_zone_id.path})/firewall/access_rules/rules";
      in
      ''
        [Definition]
        actionstart =
        actionstop =
        actioncheck =

        actionunban = id=$(curl -s -X GET "${cfapi}" \
            -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare_api_key.path})" \
            -H "Content-Type: application/json" \
            | jq -r '.result[] | select(.notes == "${notes}" and .configuration.target == "ip" and .configuration.value == "<ip>") | .id')
            if [ -z "$id" ]; then echo "ID for <ip> not found"; exit 0; fi; \
            curl -s -X DELETE "${cfapi}/$id" \
                -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare_api_key.path})" \
                -H "Content-Type: application/json"

        actionban = curl -s -X POST "${cfapi}" \
            -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare_api_key.path})" \
            -H "Content-Type: application/json" \
            --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"${notes}"}'

        [Init]
        name = cloudflare-token
      '';
  };
}