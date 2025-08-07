{ config, pkgs, ... }:
{
  # Simple log monitoring service
  systemd.services.log-watch = {
    description = "Simple Security Log Monitor";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "log-watch" ''
        # Check journald for security events
        SINCE_TIME="1 hour ago"
        
        # SSH monitoring
        SSH_FAILURES=$(journalctl --since "$SINCE_TIME" -u sshd | grep -i "failed\|invalid\|refused" | wc -l)
        if [ "$SSH_FAILURES" -gt 3 ]; then
          echo "WARNING: $SSH_FAILURES SSH security events in last hour" | \
            ${pkgs.systemd}/bin/systemd-cat -t log-watch -p warning
        fi
        
        # Sudo monitoring
        SUDO_EVENTS=$(journalctl --since "$SINCE_TIME" | grep -i "sudo.*command" | wc -l)
        if [ "$SUDO_EVENTS" -gt 10 ]; then
          echo "INFO: $SUDO_EVENTS sudo commands executed in last hour" | \
            ${pkgs.systemd}/bin/systemd-cat -t log-watch -p info
        fi
        
        # Service failures
        SERVICE_FAILURES=$(journalctl --since "$SINCE_TIME" -p err | wc -l)
        if [ "$SERVICE_FAILURES" -gt 0 ]; then
          echo "WARNING: $SERVICE_FAILURES service errors in last hour" | \
            ${pkgs.systemd}/bin/systemd-cat -t log-watch -p warning
        fi
        
        # Authentication monitoring
        AUTH_EVENTS=$(journalctl --since "$SINCE_TIME" | grep -i "authentication\|login\|session" | wc -l)
        if [ "$AUTH_EVENTS" -gt 0 ]; then
          echo "INFO: $AUTH_EVENTS authentication events in last hour" | \
            ${pkgs.systemd}/bin/systemd-cat -t log-watch -p info
        fi
        
        # Check for kernel messages
        KERNEL_WARNINGS=$(journalctl --since "$SINCE_TIME" -k -p warning | wc -l)
        if [ "$KERNEL_WARNINGS" -gt 0 ]; then
          echo "WARNING: $KERNEL_WARNINGS kernel warnings in last hour" | \
            ${pkgs.systemd}/bin/systemd-cat -t log-watch -p warning
        fi
      '';
    };
  };
  
  systemd.timers.log-watch = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "300";
    };
  };
}