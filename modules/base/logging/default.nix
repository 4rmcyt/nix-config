{ config, pkgs, ... }:
{
  # Comprehensive logging configuration
  services.journald = {
    extraConfig = ''
      # Storage configuration
      Storage=persistent
      SystemMaxUse=500M
      SystemMaxFileSize=50M
      SystemMaxFiles=10
      MaxRetentionSec=30day

      # Security settings
      ForwardToSyslog=no
      ForwardToWall=yes
      MaxLevelWall=crit

      # Rate limiting to prevent log spam
      RateLimitInterval=30s
      RateLimitBurst=10000

      # Compression
      Compress=yes
    '';
  };

  # System log rotation
  services.logrotate = {
    enable = true;
    settings = {
      # Nginx logs
      "/var/log/nginx/*.log" = {
        frequency = "daily";
        rotate = 30;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        sharedscripts = true;
        postrotate = "systemctl reload nginx || true";
      };

      # PostgreSQL logs
      "/var/log/postgresql/*.log" = {
        frequency = "daily";
        rotate = 7;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        copytruncate = true;
      };

      # System logs
      "/var/log/messages" = {
        frequency = "weekly";
        rotate = 4;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
      };
    };
  };

  # Security event monitoring
  systemd.services.security-monitor = {
    description = "Security Event Monitor";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "security-monitor" ''
        # Check for failed login attempts
        FAILED_LOGINS=$(journalctl --since "1 hour ago" | grep -c "Failed password" || echo "0")
        if [ "$FAILED_LOGINS" -gt 10 ]; then
          echo "WARNING: $FAILED_LOGINS failed login attempts in last hour" | \
            systemd-cat -t security-monitor -p warning
        fi

        # Check for privilege escalation attempts
        SUDO_FAILURES=$(journalctl --since "1 hour ago" | grep -c "sudo.*FAILED" || echo "0")
        if [ "$SUDO_FAILURES" -gt 5 ]; then
          echo "WARNING: $SUDO_FAILURES sudo failures in last hour" | \
            systemd-cat -t security-monitor -p warning
        fi

        # Check for system modification attempts
        SYSTEM_CHANGES=$(journalctl --since "1 hour ago" | grep -c -E "(passwd|group|shadow|sudoers)" || echo "0")
        if [ "$SYSTEM_CHANGES" -gt 0 ]; then
          echo "INFO: $SYSTEM_CHANGES system file modifications in last hour" | \
            systemd-cat -t security-monitor -p info
        fi
      '';
    };
  };

  systemd.timers.security-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "300";
    };
  };
}
