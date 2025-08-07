{ config, pkgs, ... }:
{
  # Network intrusion detection with Suricata
  services.suricata = {
    enable = true;
    
    settings = {
      # Network interfaces
      af-packet = [
        {
          interface = "enp3s0";  # Adjust to your interface
          cluster-id = 99;
          cluster-type = "cluster_flow";
          defrag = true;
        }
      ];
      
      # Detection settings
      detect = {
        profile = "medium";
        custom-values = {
          toclient-groups = 3;
          toserver-groups = 25;
        };
      };
      
      # Output configuration
      outputs = [
        {
          eve-log = {
            enabled = true;
            filetype = "regular";
            filename = "/var/log/suricata/eve.json";
            
            types = [
              { alert = { tagged-packets = true; }; }
              { http = { extended = true; }; }
              { dns = { enabled = true; }; }
              { tls = { extended = true; }; }
              { ssh = { enabled = true; }; }
              { smtp = { enabled = true; }; }
              { flow = { enabled = true; }; }
            ];
          };
        }
        {
          unified2-alert = {
            enabled = false;
          };
        }
      ];
      
      # Logging
      logging = {
        default-log-level = "notice";
        outputs = [
          {
            console = {
              enabled = true;
            };
          }
          {
            file = {
              enabled = true;
              level = "info";
              filename = "/var/log/suricata/suricata.log";
            };
          }
          {
            syslog = {
              enabled = true;
              facility = "local5";
              format = "[%i] <%d> -- ";
            };
          };
        ];
      };
    };
  };
  
  # Suricata rule management
  systemd.services.suricata-update = {
    description = "Update Suricata rules";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "suricata-update" ''
        # Update rules from various sources
        ${pkgs.suricata}/bin/suricata-update update-sources
        ${pkgs.suricata}/bin/suricata-update
        
        # Reload Suricata
        ${pkgs.systemd}/bin/systemctl reload suricata
        
        echo "Suricata rules updated" | \
          ${pkgs.systemd}/bin/systemd-cat -t suricata-update -p info
      '';
    };
  };
  
  systemd.timers.suricata-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "2h";
    };
  };
  
  # Log analysis service
  systemd.services.suricata-analyzer = {
    description = "Analyze Suricata alerts";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "suricata-analyzer" ''
        LOG_FILE="/var/log/suricata/eve.json"
        
        if [ ! -f "$LOG_FILE" ]; then
          echo "Suricata log file not found"
          exit 0
        fi
        
        # Check for recent alerts (last hour)
        RECENT_ALERTS=$(jq -r 'select(.timestamp >= (now - 3600 | strftime("%Y-%m-%dT%H:%M:%S"))) | select(.event_type == "alert")' "$LOG_FILE" 2>/dev/null | wc -l)
        
        if [ "$RECENT_ALERTS" -gt 0 ]; then
          echo "WARNING: $RECENT_ALERTS security alerts in the last hour" | \
            ${pkgs.systemd}/bin/systemd-cat -t suricata-analyzer -p warning
          
          # Log top alert types
          jq -r 'select(.timestamp >= (now - 3600 | strftime("%Y-%m-%dT%H:%M:%S"))) | select(.event_type == "alert") | .alert.signature' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -5 | \
            ${pkgs.systemd}/bin/systemd-cat -t suricata-alerts -p info
        fi
        
        # Check for suspicious connections
        SUSPICIOUS_CONNS=$(jq -r 'select(.timestamp >= (now - 3600 | strftime("%Y-%m-%dT%H:%M:%S"))) | select(.event_type == "flow") | select(.flow.reason == "timeout")' "$LOG_FILE" 2>/dev/null | wc -l)
        
        if [ "$SUSPICIOUS_CONNS" -gt 100 ]; then
          echo "WARNING: $SUSPICIOUS_CONNS suspicious network connections detected" | \
            ${pkgs.systemd}/bin/systemd-cat -t suricata-analyzer -p warning
        fi
      '';
    };
  };
  
  systemd.timers.suricata-analyzer = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "300";
    };
  };
}