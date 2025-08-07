{ config, pkgs, ... }:
{
  # =================================================================
  # 1. Journald Configuration
  # Using structured options for better readability and error-checking.
  # =================================================================
  services.journald = {
    storage = "persistent";
    extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=50M
      SystemMaxFiles=10
      MaxRetentionSec=30day
      ForwardToSyslog=no
      ForwardToWall=yes
      MaxLevelWall=crit
      RateLimitInterval=30s
      RateLimitBurst=10000
      Compress=yes
    '';
  };

  # =================================================================
  # 2. Logrotate for Application-Specific Logs
  # =================================================================
  services.logrotate = {
    enable = true;
    settings = {
      # This is correct for services that write to their own log files.
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

      # This is also correct for PostgreSQL's dedicated logs.
      "/var/log/postgresql/*.log" = {
        frequency = "daily";
        rotate = 7;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        copytruncate = true;
      };

      # The entry for "/var/log/messages" has been removed, as journald
      # now handles all system log rotation natively.
    };
  };

  # =================================================================
  # 3. Custom Security Event Monitoring
  # =================================================================
  systemd.services.security-monitor = {
    description = "Security Event Monitor";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "security-monitor" ''
        # This script now focuses on detecting log patterns for failed access attempts.
        # File integrity monitoring is left to the more robust 'auditd' system.

        # Check for failed login attempts
        FAILED_LOGINS=$(journalctl --since "1 hour ago" | grep -c "Failed password" || echo "0")
        if [ "$FAILED_LOGINS" -gt 10 ]; then
          echo "WARNING: $FAILED_LOGINS failed login attempts in the last hour" | \
            systemd-cat -t security-monitor -p warning
        fi

        # Check for privilege escalation failures
        SUDO_FAILURES=$(journalctl --since "1 hour ago" | grep -c "sudo.*authentication failure" || echo "0")
        if [ "$SUDO_FAILURES" -gt 5 ]; then
          echo "WARNING: $SUDO_FAILURES sudo failures in the last hour" | \
            systemd-cat -t security-monitor -p warning
        fi
      '';
    };
  };

  systemd.timers.security-monitor = {
    description = "Run security monitor script hourly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5m"; # Use 'm' for minutes for clarity
    };
  };
}
