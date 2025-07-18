{ config, pkgs, lib, ... }:

{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    extraPackages = [ pkgs.curl pkgs.jq ];

    # Ensure fail2ban starts after secrets are available

    ignoreIP = [
      "127.0.0.0/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      # Cloudflare's official IP ranges
      "173.245.48.0/20" "103.21.244.0/22" "103.22.200.0/22" "103.31.4.0/22"
      "141.101.64.0/18" "108.162.192.0/18" "190.93.240.0/20" "188.114.96.0/20"
      "197.234.240.0/22" "198.41.128.0/17" "162.158.0.0/15" "104.16.0.0/13"
      "104.24.0.0/14" "172.64.0.0/13" "131.0.72.0/22" "2400:cb00::/32"
      "2606:4700::/32" "2803:f800::/32" "2405:b500::/32" "2405:8100::/32"
      "2a06:98c0::/29" "2c0f:f248::/32"
    ];

    jails = {
      # This is now a string, not an attribute set, to match the module's expectation
      sshd = ''
        enabled = true
        backend = systemd
        journalmatch = _SYSTEMD_UNIT=sshd.service
        maxretry = 3
        bantime = 1h
        action = cloudflare-token
      '';
      # You can continue to add other jails in this format
      # nextcloud = '' ... '';
    };
  };

  # Custom filters and actions
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

    # ... other custom filters ...

    # Cloudflare action configuration with corrected secret paths
    "fail2ban/action.d/cloudflare-token.conf".text =
      let
        notes = "Fail2Ban-${config.networking.hostName}";
        # The Zone ID can be interpolated directly as a string
        zoneId = config.sops.secrets.cloudflare_secrets.cloudflare_zone_id;
        # The API key needs a dedicated file path
        apiKeyFile = config.sops.secrets.cloudflare_api_key.path;
        cfapi = "https://api.cloudflare.com/client/v4/zones/${zoneId}/firewall/access_rules/rules";
      in
      ''
        [Definition]
        actionstart =
        actionstop =
        actioncheck =

        actionunban = id=$(curl -s -X GET "${cfapi}" \
            -H "Authorization: Bearer $(cat ${apiKeyFile})" \
            -H "Content-Type: application/json" \
            | jq -r '.result[] | select(.notes == "${notes}" and .configuration.target == "ip" and .configuration.value == "<ip>") | .id')
            if [ -z "$id" ]; then echo "ID for <ip> not found"; exit 0; fi; \
            curl -s -X DELETE "${cfapi}/$id" \
                -H "Authorization: Bearer $(cat ${apiKeyFile})" \
                -H "Content-Type: application/json"

        actionban = curl -s -X POST "${cfapi}" \
            -H "Authorization: Bearer $(cat ${apiKeyFile})" \
            -H "Content-Type: application/json" \
            --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"${notes}"}'

        [Init]
        name = cloudflare-token
      '';
  };
}
