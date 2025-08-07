{ config, pkgs, ... }:
{
  # Lightweight network monitoring using built-in tools
  systemd.services.network-monitor = {
    description = "Lightweight Network Security Monitor";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "network-monitor" ''
        # Check for unusual network connections
        EXTERNAL_CONNS=$(ss -tuln | grep -v '127.0.0.1\|::1' | wc -l)
        if [ "$EXTERNAL_CONNS" -gt 50 ]; then
          echo "INFO: $EXTERNAL_CONNS external network connections active" | \
            ${pkgs.systemd}/bin/systemd-cat -t network-monitor -p info
        fi
        
        # Check for failed connection attempts in auth.log
        if [ -f /var/log/auth.log ]; then
          FAILED_SSH=$(grep "Failed password" /var/log/auth.log | tail -100 | grep "$(date '+%b %d')" | wc -l)
          if [ "$FAILED_SSH" -gt 5 ]; then
            echo "WARNING: $FAILED_SSH SSH login failures today" | \
              ${pkgs.systemd}/bin/systemd-cat -t network-monitor -p warning
          fi
        fi
        
        # Check for unusual port activity
        LISTENING_PORTS=$(ss -tln | awk 'NR>1 {print $4}' | cut -d: -f2 | sort -n | uniq | wc -l)
        echo "INFO: $LISTENING_PORTS unique ports listening" | \
          ${pkgs.systemd}/bin/systemd-cat -t network-monitor -p info
        
        # Monitor bandwidth usage (basic check)
        RX_BYTES=$(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | awk '{sum+=$1} END {print sum/1024/1024}')
        TX_BYTES=$(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | awk '{sum+=$1} END {print sum/1024/1024}')
        echo "INFO: Network usage - RX: ${RX_BYTES}MB, TX: ${TX_BYTES}MB total" | \
          ${pkgs.systemd}/bin/systemd-cat -t network-monitor -p info
      '';
    };
  };
  
  systemd.timers.network-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/15";  # Every 15 minutes
      Persistent = true;
    };
  };
}