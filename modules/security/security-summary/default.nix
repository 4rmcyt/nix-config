{ config, pkgs, ... }:
{
  # Enhanced daily security summary with Grafana integration
  systemd.services.security-summary = {
    description = "Daily Security Summary with Grafana Integration";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "security-summary" ''
        echo "=== Daily Security Summary $(date) ===" | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

        # System uptime
        UPTIME=$(uptime -p)
        echo "System uptime: $UPTIME" | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

        # Failed login attempts
        FAILED_LOGINS=$(journalctl --since "24 hours ago" | grep -i "failed.*password\|authentication failure" | wc -l)
        echo "Failed login attempts (24h): $FAILED_LOGINS" | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

        # Service status
        FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
        echo "Failed systemd services: $FAILED_SERVICES" | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

        # Disk usage
        echo "Disk usage:" | ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
        df -h | grep -E "^/dev" | awk '{print $1 ": " $5 " used"}' | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

        # Memory usage
        MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f%%", $3*100/$2}')
        echo "Memory usage: $MEMORY_USAGE" | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

        # Sudo commands
        SUDO_COUNT=$(journalctl --since "24 hours ago" | grep "sudo.*COMMAND" | wc -l)
        echo "Sudo commands executed (24h): $SUDO_COUNT" | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

        # Grafana dashboard link
        echo "View detailed metrics: http://localhost:3000/d/security-overview" | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

        # Generate summary for Grafana annotation
        SUMMARY_JSON="/var/lib/grafana/daily-summary.json"
        cat > "$SUMMARY_JSON" << EOF
        {
          "time": $(date +%s)000,
          "title": "Daily Security Summary",
          "text": "Failed logins: $FAILED_LOGINS, Failed services: $FAILED_SERVICES, Memory: $MEMORY_USAGE, Sudo commands: $SUDO_COUNT",
          "tags": ["security", "daily-summary"]
        }
        EOF
        chown grafana:grafana "$SUMMARY_JSON" 2>/dev/null || true

        echo "=== End Security Summary ===" | \
          ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
      '';
    };
  };

  systemd.timers.security-summary = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
