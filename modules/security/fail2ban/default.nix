{
  config,
  lib,
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
      # real client IP for Cloudflare's proxy IPs is in X-Forwarded-For
      ++ config.my.network.subnets.cloudflare;

    # SSH isn't proxied through Cloudflare, so %(action_)s (local ban) is what
    # actually blocks the attacker; cloudflare-waf is added on top.
    jails.sshd.settings = {
      enabled = true;
      maxretry = 3;
      bantime = "24h";
      findtime = "10m";
      action = ''
        %(action_)s
          cloudflare-waf
      '';
    };

    # traefik-auth jail removed — CrowdSec now handles Traefik log parsing (JSON access log).

    # Jellyfin isn't tunneled through Cloudflare, so the local ban is what actually
    # blocks the attacker; cloudflare-waf is defense-in-depth only.
    jails.jellyfin = ''
      enabled      = true
      backend      = systemd
      filter       = jellyfin
      journalmatch = _SYSTEMD_UNIT=jellyfin.service
      maxretry     = 5
      bantime      = 2h
      findtime     = 10m
      action       = %(action_)s
                      cloudflare-waf
    '';

    # Same reasoning as jellyfin above; uses the filter shipped by the fail2ban
    # package itself, which matches Grafana's actual log15 output (`lvl=`, not `level=`).
    jails.grafana = ''
      enabled      = true
      backend      = systemd
      filter       = grafana
      journalmatch = _SYSTEMD_UNIT=grafana.service
      maxretry     = 5
      bantime      = 2h
      findtime     = 10m
      action       = %(action_)s
                      cloudflare-waf
    '';

    # hass is tunneled through Cloudflare, so cloudflare-waf alone is effective here;
    # local ban is added for direct-LAN access too.
    jails.home-assistant = ''
      enabled      = true
      backend      = systemd
      filter       = home-assistant
      journalmatch = _SYSTEMD_UNIT=home-assistant.service
      maxretry     = 5
      bantime      = 2h
      findtime     = 10m
      action       = %(action_)s
                      cloudflare-waf
    '';
  };

  environment.etc = {
    # Replaces the deprecated firewall/access_rules API (stopped working May 2024).
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

    # No custom grafana.conf here: fail2ban 1.1.1+ ships its own filter.d/grafana.conf
    # and ours collided with it ("mismatched duplicate entry") while also never
    # matching real lines (ours checked `level=`, Grafana's log15 emits `lvl=`).

    "fail2ban/filter.d/home-assistant.conf" = {
      mode = "0644";
      text = ''
        [Definition]
        failregex = ^.*Login attempt or request with invalid authentication from <HOST>.*$
        ignoreregex =
      '';
    };

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

  systemd.tmpfiles.rules = [
    "d /run/fail2ban 0750 root root -"
  ];

  # fail2ban's own module already runs as root with a narrow CapabilityBoundingSet and
  # ProtectSystem=strict (root needed for nftables/iptables + root-owned logs); these
  # are additive-only toggles the module doesn't set.
  systemd.services.fail2ban.serviceConfig = {
    ProtectClock = lib.mkDefault true;
    ProtectKernelLogs = lib.mkDefault true;
    MemoryDenyWriteExecute = lib.mkDefault true;
    RestrictNamespaces = lib.mkDefault true;
    LockPersonality = lib.mkDefault true;
    RestrictRealtime = lib.mkDefault true;
    RestrictSUIDSGID = lib.mkDefault true;
    SystemCallArchitectures = lib.mkDefault "native";
    # AF_NETLINK for nftables/iptables, AF_UNIX for journald, AF_INET/INET6 for cloudflare-waf's curl.
    RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
    ProtectProc = lib.mkDefault "invisible";
    ProcSubset = lib.mkDefault "pid";
    UMask = lib.mkDefault "0077";
    SystemCallFilter = lib.mkDefault ["@system-service"];
    # PrivateUsers deliberately NOT set: breaks CAP_NET_ADMIN/CAP_NET_RAW netlink access
    # the same way it broke caddy/crowdsec on gcp-relay (pulled preemptively, untested here).
  };
}
