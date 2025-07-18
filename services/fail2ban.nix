{ config, pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    maxretry = 5;

    extraPackages = [ pkgs.curl pkgs.jq ];

    ignoreIP = [
      "127.0.0.0/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      # Add Cloudflare's official IP ranges
      "173.245.48.0/20"
      "103.21.244.0/22"
      "103.22.200.0/22"
      "103.31.4.0/22"
      "141.101.64.0/18"
      "108.162.192.0/18"
      "190.93.240.0/20"
      "188.114.96.0/20"
      "197.234.240.0/22"
      "198.41.128.0/17"
      "162.158.0.0/15"
      "104.16.0.0/13"
      "104.24.0.0/14"
      "172.64.0.0/13"
      "131.0.72.0/22"
      "2400:cb00::/32"
      "2606:4700::/32"
      "2803:f800::/32"
      "2405:b500::/32"
      "2405:8100::/32"
      "2a06:98c0::/29"
      "2c0f:f248::/32"
    ];

    jails = {
      ssh = {
        settings = {
          enabled = true;
          # Change these two lines for consistency
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=sshd.service";
          
          maxretry = 3;
          bantime = "1h";
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

      miniflux = {
        settings = {
          enabled = true;
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=miniflux.service";
          filter = "miniflux";
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
      kavita = {
        settings = {
          enabled = true;
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=kavita.service";
          filter = "kavita";
          maxretry = 5;
          findtime = "10m";
          bantime = "1h";
          action = "cloudflare-token";
        };
      };
      transmission = {
        settings = {
          enabled = true;
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=transmission.service";
          filter = "transmission";
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

    "fail2ban/filter.d/audiobookshelf.conf".text = ''
      [Definition]
      failregex = Failed login attempt.*ip=<HOST>
                  Invalid credentials.*ip=<HOST>
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
            -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare.cloudflare_api_key.path})" \
            -H "Content-Type: application/json" \
            | jq -r '.result[] | select(.notes == "${notes}" and .configuration.target == "ip" and .configuration.value == "<ip>") | .id')
            if [ -z "$id" ]; then echo "ID for <ip> not found"; exit 0; fi; \
            curl -s -X DELETE "${cfapi}/$id" \
                -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare.cloudflare_api_key.path})" \
                -H "Content-Type: application/json"

        actionban = curl -s -X POST "${cfapi}" \
            -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare.cloudflare_api_key.path})" \
            -H "Content-Type: application/json" \
            --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"${notes}"}'

        [Init]
        name = cloudflare-token
      '';
  };
}