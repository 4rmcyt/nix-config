{ config, pkgs, ... }:
{
  # Security metrics exporter for Grafana
  systemd.services.security-metrics-exporter = {
    description = "Security Metrics Exporter for Grafana";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "security-metrics-exporter" ''
        METRICS_FILE="/var/lib/grafana/security-metrics.json"
        TEMP_FILE="/tmp/security-metrics.json"

        # Create metrics directory
        mkdir -p /var/lib/grafana

        # Generate timestamp
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        EPOCH=$(date +%s)

        # Start JSON structure
        cat > "$TEMP_FILE" << EOF
        {
          "timestamp": "$TIMESTAMP",
          "epoch": $EPOCH,
          "metrics": {
        EOF

        # Failed login attempts (last 24h)
        FAILED_LOGINS=$(journalctl --since "24 hours ago" --no-pager | grep -i "failed.*password\|authentication failure" | wc -l)
        echo "    \"failed_logins_24h\": $FAILED_LOGINS," >> "$TEMP_FILE"

        # Failed SSH attempts (last 1h)
        FAILED_SSH_1H=$(journalctl --since "1 hour ago" --no-pager | grep -i "failed password.*ssh\|invalid user.*ssh" | wc -l)
        echo "    \"failed_ssh_1h\": $FAILED_SSH_1H," >> "$TEMP_FILE"

        # Sudo commands (last 24h)
        SUDO_COUNT=$(journalctl --since "24 hours ago" --no-pager | grep "sudo.*COMMAND" | wc -l)
        echo "    \"sudo_commands_24h\": $SUDO_COUNT," >> "$TEMP_FILE"

        # Failed systemd services
        FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
        echo "    \"failed_services\": $FAILED_SERVICES," >> "$TEMP_FILE"

        # Active network connections
        ACTIVE_CONNECTIONS=$(ss -tuln | grep -v '127.0.0.1\|::1' | wc -l)
        echo "    \"active_connections\": $ACTIVE_CONNECTIONS," >> "$TEMP_FILE"

        # Memory usage percentage
        MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        echo "    \"memory_usage_percent\": $MEMORY_USAGE," >> "$TEMP_FILE"

        # CPU usage (1-minute load average relative to CPU cores)
        LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        CPU_CORES=$(nproc)
        CPU_USAGE_PERCENT=$(echo "scale=0; $LOAD_AVG * 100 / $CPU_CORES" | bc -l 2>/dev/null || echo "0")
        echo "    \"cpu_usage_percent\": $CPU_USAGE_PERCENT," >> "$TEMP_FILE"

        # Disk usage for critical partitions
        ROOT_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
        echo "    \"disk_root_usage_percent\": $ROOT_USAGE," >> "$TEMP_FILE"

        BOOT_USAGE=$(df /boot | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0")
        echo "    \"disk_boot_usage_percent\": $BOOT_USAGE," >> "$TEMP_FILE"

        # Temperature (if available)
        CPU_TEMP=$(sensors 2>/dev/null | grep -E "(Core 0|Package id 0|Tctl)" | head -1 | awk '{print $3}' | sed 's/[+°C]//g' | cut -d'.' -f1 2>/dev/null || echo "0")
        echo "    \"cpu_temperature_celsius\": $CPU_TEMP," >> "$TEMP_FILE"

        # Fail2ban banned IPs
        BANNED_IPS=0
        if systemctl is-active --quiet fail2ban; then
          BANNED_IPS=$(${pkgs.fail2ban}/bin/fail2ban-client status 2>/dev/null | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | while read jail; do
            if [ -n "$(echo $jail | tr -d ' ')" ]; then
              ${pkgs.fail2ban}/bin/fail2ban-client status "$(echo $jail | tr -d ' ')" 2>/dev/null | grep "Currently banned:" | awk '{print $3}'
            fi
          done | awk '{sum+=$1} END {print sum+0}')
        fi
        echo "    \"fail2ban_banned_ips\": $BANNED_IPS," >> "$TEMP_FILE"

        # System uptime in hours
        UPTIME_HOURS=$(awk '{print int($1/3600)}' /proc/uptime)
        echo "    \"uptime_hours\": $UPTIME_HOURS," >> "$TEMP_FILE"

        # Open ports count
        OPEN_PORTS=$(ss -tln | awk 'NR>1 {print $4}' | cut -d: -f2 | sort -n | uniq | wc -l)
        echo "    \"open_ports_count\": $OPEN_PORTS," >> "$TEMP_FILE"

        # ZFS pool health (if ZFS is used)
        ZFS_HEALTH=1  # 1 = healthy, 0 = issues
        if command -v zpool >/dev/null 2>&1; then
          for pool in $(zpool list -H -o name 2>/dev/null); do
            if ! zpool status "$pool" | grep -q "state: ONLINE"; then
              ZFS_HEALTH=0
              break
            fi
          done
        fi
        echo "    \"zfs_health_status\": $ZFS_HEALTH," >> "$TEMP_FILE"

        # Remove last comma and close JSON
        sed -i '$ s/,$//' "$TEMP_FILE"
        cat >> "$TEMP_FILE" << EOF
          }
        }
        EOF

        # Move to final location atomically
        mv "$TEMP_FILE" "$METRICS_FILE"
        chown grafana:grafana "$METRICS_FILE" 2>/dev/null || true
        chmod 644 "$METRICS_FILE"

        echo "Security metrics exported to $METRICS_FILE"
      '';

      # Security settings
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/var/lib/grafana"
        "/tmp"
      ];
      ReadOnlyPaths = [
        "/proc"
        "/sys"
      ];
    };
  };

  systemd.timers.security-metrics-exporter = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5"; # Every 5 minutes
      Persistent = true;
      AccuracySec = "30s";
    };
  };
}
