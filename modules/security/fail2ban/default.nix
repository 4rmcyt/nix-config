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
      # Cloudflare proxy IPs — real client IP is in X-Forwarded-For
      ++ config.my.network.subnets.cloudflare;

    # SSH — NixOS defines this jail automatically when openssh is enabled.
    # We override settings to tighten it up and add the cloudflare-waf action
    # alongside (not instead of) the local ban — SSH isn't proxied through
    # Cloudflare, so %(action_)s is what actually blocks the attacker.
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

    # traefik-auth jail removed — CrowdSec handles Traefik log parsing
    # (access log is now JSON format, parsed by crowdsecurity/traefik collection)

    # Jellyfin — reached directly via Traefik (not tunneled through
    # Cloudflare), so the local ban (%(action_)s) is what actually blocks
    # the attacker; cloudflare-waf is added defense-in-depth only.
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

    # Grafana — reached directly via Traefik (not tunneled through
    # Cloudflare); same reasoning as the jellyfin jail above.
    # Pattern: level=warn ... msg="Invalid username or password" ... remote_addr=<ip>
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

    # Home Assistant — tunneled through Cloudflare (hass in cloudflared's
    # tunnel list), so cloudflare-waf alone is effective here; local ban
    # added anyway for defense-in-depth / direct-LAN access.
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

  # nixpkgs' fail2ban module already runs as root with a narrow
  # CapabilityBoundingSet (cap_dac_read_search, cap_net_admin, cap_net_raw,
  # cap_audit_read — verified via `systemctl show fail2ban.service`) and
  # ProtectSystem=strict; root is required (manages nftables/iptables bans
  # and reads root-owned logs), not fixable here. The toggles below are
  # additive sandboxing the module doesn't set at all — none grant or
  # require any capability, so they're safe regardless of jail config.
  systemd.services.fail2ban.serviceConfig = {
    ProtectClock = lib.mkDefault true;
    ProtectKernelLogs = lib.mkDefault true;
    MemoryDenyWriteExecute = lib.mkDefault true;
    RestrictNamespaces = lib.mkDefault true;
    LockPersonality = lib.mkDefault true;
    RestrictRealtime = lib.mkDefault true;
    RestrictSUIDSGID = lib.mkDefault true;
    SystemCallArchitectures = lib.mkDefault "native";
    # AF_NETLINK required (nftables/iptables manipulation), AF_UNIX for
    # journald reads, AF_INET/INET6 for the cloudflare-waf action's curl calls.
    RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
    ProtectProc = lib.mkDefault "invisible";
    ProcSubset = lib.mkDefault "pid";
    UMask = lib.mkDefault "0077";
    SystemCallFilter = lib.mkDefault ["@system-service"];
    # No IPAddressDeny/Allow — cloudflare-waf action needs unrestricted
    # outbound to api.cloudflare.com.
    #
    # PrivateUsers deliberately NOT set: fail2ban needs CAP_NET_ADMIN/
    # CAP_NET_RAW netlink access to manipulate nftables/iptables bans, which
    # breaks the same way caddy's CAP_NET_BIND_SERVICE and crowdsec's
    # CAP_NET_ADMIN did on gcp-relay when PrivateUsers put them in their own
    # user namespace (kernel's privileged network checks don't carry over).
    # Never actually failed here — just hadn't banned anyone yet since
    # reboot — pulled preemptively.
  };
}
