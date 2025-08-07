{ config, pkgs, ... }:
{
  # Enhanced fail2ban with better monitoring
  services.fail2ban = {
    enable = true;

    # Lightweight but effective configuration
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "168h"; # 1 week max
      factor = "2";
    };

    maxretry = 3;
    findtime = "10m";

    # Ignore local networks
    ignoreIP = [
      "127.0.0.1/8"
      "10.0.0.0/8"
      "192.168.0.0/16"
      "172.16.0.0/12"
    ];

    jails = {
      # SSH protection (essential)
      sshd = {
        enabled = true;
        port = "ssh";
        filter = "sshd";
        logpath = "/var/log/auth.log";
        maxretry = 3;
        bantime = "1h";
      };

      # Nginx protection (if using nginx)
      nginx-http-auth = {
        enabled = true;
        port = "http,https";
        filter = "nginx-http-auth";
        logpath = "/var/log/nginx/error.log";
        maxretry = 3;
      };

      nginx-limit-req = {
        enabled = true;
        port = "http,https";
        filter = "nginx-limit-req";
        logpath = "/var/log/nginx/error.log";
        maxretry = 10;
        findtime = "10m";
        bantime = "30m";
      };

      # General authentication failures
      pam-generic = {
        enabled = true;
        filter = "pam-generic";
        logpath = "/var/log/auth.log";
        maxretry = 3;
        bantime = "1h";
      };
    };
  };

  # Fail2ban monitoring
  systemd.services.fail2ban-monitor = {
    description = "Monitor Fail2ban Activity";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "fail2ban-monitor" ''
        # Check fail2ban status
        if ! systemctl is-active --quiet fail2ban; then
          echo "CRITICAL: Fail2ban service is not running" | \
            ${pkgs.systemd}/bin/systemd-cat -t fail2ban-monitor -p crit
          exit 1
        fi

        # Count current bans
        BANNED_IPS=$(${pkgs.fail2ban}/bin/fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | while read jail; do
          if [ -n "$jail" ]; then
            ${pkgs.fail2ban}/bin/fail2ban-client status "$jail" 2>/dev/null | grep "Currently banned:" | awk '{print $3}'
          fi
        done | awk '{sum+=$1} END {print sum+0}')

        if [ "$BANNED_IPS" -gt 0 ]; then
          echo "INFO: $BANNED_IPS IP addresses currently banned by fail2ban" | \
            ${pkgs.systemd}/bin/systemd-cat -t fail2ban-monitor -p info
        fi

        # Check for new bans in the last hour
        NEW_BANS=$(journalctl --since "1 hour ago" -u fail2ban | grep "Ban " | wc -l)
        if [ "$NEW_BANS" -gt 0 ]; then
          echo "WARNING: $NEW_BANS new IP bans in the last hour" | \
            ${pkgs.systemd}/bin/systemd-cat -t fail2ban-monitor -p warning
        fi
      '';
    };
  };

  systemd.timers.fail2ban-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/30"; # Every 30 minutes
      Persistent = true;
    };
  };
}
