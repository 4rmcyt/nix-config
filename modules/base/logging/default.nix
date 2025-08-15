{ pkgs, ... }:
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
  # 2. Custom Security Event Monitoring
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
