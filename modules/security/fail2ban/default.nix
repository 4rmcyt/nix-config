{
  config,
  pkgs,
  ...
}: let
  zoneIdFile = config.sops.secrets.cloudflare_zone_id.path;
  apiKeyFile = config.sops.secrets.cloudflare_api_key.path;
  notes = "Fail2Ban-${config.networking.hostName}";
in {
  sops.secrets = {
    cloudflare_zone_id.sopsFile = ../../../secrets/cloudflare.yaml;
    cloudflare_api_key.sopsFile = ../../../secrets/cloudflare.yaml;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "2 4 8 16 32 64";
      maxtime = "168h"; # 1 week cap
      overalljails = true;
    };

    extraPackages = with pkgs; [
      curl
      jq
    ];

    ignoreIP =
      [
        "127.0.0.0/8"
        "10.0.0.0/8"
      ]
      ++ config.my.network.subnets.lan
      ++ [config.my.network.subnets.tailscale]
      # Cloudflare proxy IPs — real client IP is in X-Forwarded-For
      ++ config.my.network.subnets.cloudflare;

    # SSH — NixOS defines this jail automatically when openssh is enabled.
    # We override settings to tighten it up and use cloudflare-waf action.
    jails.sshd.settings = {
      enabled = true;
      maxretry = 3;
      bantime = "24h";
      findtime = "10m";
      action = "cloudflare-waf";
    };

    # traefik-auth jail removed — CrowdSec handles Traefik log parsing
    # (access log is now JSON format, parsed by crowdsecurity/traefik collection)

    # Jellyfin — logs real IP in its own journal entries
    jails.jellyfin = ''
      enabled      = true
      backend      = systemd
      filter       = jellyfin
      journalmatch = _SYSTEMD_UNIT=jellyfin.service
      maxretry     = 5
      bantime      = 2h
      findtime     = 10m
      action       = cloudflare-waf
    '';

    # Grafana — logs failed logins with IP to journal
    # Pattern: level=warn ... msg="Invalid username or password" ... remote_addr=<ip>
    jails.grafana = ''
      enabled      = true
      backend      = systemd
      filter       = grafana
      journalmatch = _SYSTEMD_UNIT=grafana.service
      maxretry     = 5
      bantime      = 2h
      findtime     = 10m
      action       = cloudflare-waf
    '';

    # Home Assistant — logs failed logins with IP to journal
    jails.home-assistant = ''
      enabled      = true
      backend      = systemd
      filter       = home-assistant
      journalmatch = _SYSTEMD_UNIT=home-assistant.service
      maxretry     = 5
      bantime      = 2h
      findtime     = 10m
      action       = cloudflare-waf
    '';
  };

  environment.etc = {
    # Cloudflare WAF Custom Rules action (replaces deprecated
    # firewall/access_rules API which stopped working May 2024).
    # Creates a per-IP block rule in the zone's WAF custom ruleset;
    # deletes it on unban using the rule ID stored in a temp file.
    "fail2ban/action.d/cloudflare-waf.conf" = {
      mode = "0644";
      text = ''
        [Definition]
        actionban = RULE_ID=$(curl -s -X POST \
            "https://api.cloudflare.com/client/v4/zones/$(cat ${zoneIdFile})/rulesets/phases/http_request_firewall_custom/entrypoint/rules" \
            -H "Authorization: Bearer $(cat ${apiKeyFile})" \
            -H "Content-Type: application/json" \
            --data "{\"description\":\"${notes} <ip>\",\"expression\":\"(ip.src eq <ip>)\",\"action\":\"block\",\"enabled\":true}" \
            | jq -r '.result.id // empty'); \
            [ -n "$RULE_ID" ] && echo "$RULE_ID" > /run/fail2ban/cf-<ip>.id || true

        actionunban = if [ -f /run/fail2ban/cf-<ip>.id ]; then \
            RULE_ID=$(cat /run/fail2ban/cf-<ip>.id); \
            curl -s -X DELETE \
                "https://api.cloudflare.com/client/v4/zones/$(cat ${zoneIdFile})/rulesets/phases/http_request_firewall_custom/entrypoint/rules/$RULE_ID" \
                -H "Authorization: Bearer $(cat ${apiKeyFile})" \
                -H "Content-Type: application/json"; \
            rm -f /run/fail2ban/cf-<ip>.id; \
            fi

        [Init]
        name = cloudflare-waf
      '';
    };

    # Grafana filter — matches failed login entries from journal.
    # Pattern: level=warn ... msg="Invalid username or password" ... remote_addr=<ip>
    "fail2ban/filter.d/grafana.conf" = {
      mode = "0644";
      text = ''
        [Definition]
        failregex = ^.*level=warn.*msg="Invalid username or password".*remote_addr=<HOST>.*$
        ignoreregex =
      '';
    };

    # Home Assistant filter — matches failed login log entries.
    # HASS logs: Login attempt or request with invalid authentication
    # from <ip> (<user agent>)
    "fail2ban/filter.d/home-assistant.conf" = {
      mode = "0644";
      text = ''
        [Definition]
        failregex = ^.*Login attempt or request with invalid authentication from <HOST>.*$
        ignoreregex =
      '';
    };

    # Jellyfin filter — matches journald entries for denied auth.
    # Pattern from upstream jellyfin/jellyfin issue #5057.
    "fail2ban/filter.d/jellyfin.conf" = {
      mode = "0644";
      text = ''
        [Definition]
        failregex = Authentication request for ".*" has been denied \(IP: "<HOST>"\)\.
        ignoreregex =
      '';
    };
  };

  # Ensure /run/fail2ban exists for storing CF rule IDs
  systemd.tmpfiles.rules = [
    "d /run/fail2ban 0750 root root -"
  ];
}
