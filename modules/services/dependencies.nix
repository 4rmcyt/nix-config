# Service dependency and startup order management
{ config, lib, ... }:
{
  # Define service startup order
  systemd.services = {
    # Database services first
    postgresql.wantedBy = lib.mkForce [ "multi-user.target" ];
    redis-default.after = [ "postgresql.service" ];

    # Application services after databases
    home-assistant.after = [
      "postgresql.service"
      "redis-default.service"
    ];
    authentik.after = [
      "postgresql.service"
      "redis-authentik.service"
    ];
    miniflux.after = [ "postgresql.service" ];

    # Web services last
    nginx.after = [
      "home-assistant.service"
      "authentik.service"
      "miniflux.service"
      "grafana.service"
    ];

    # Backup services run when others are stable
    borgmatic.after = [
      "postgresql.service"
      "postgresqlBackup.service"
      "home-assistant.service"
    ];
  };

  # Add service health checks
  systemd.services.service-health-monitor = {
    description = "Monitor critical service health";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "service-health" ''
        CRITICAL_SERVICES=(
          "postgresql"
          "nginx" 
          "sshd"
          "NetworkManager"
        )

        failed_services=()
        for service in "''${CRITICAL_SERVICES[@]}"; do
          if ! systemctl is-active --quiet "$service"; then
            failed_services+=("$service")
          fi
        done

        if [ ''${#failed_services[@]} -gt 0 ]; then
          echo "CRITICAL: Failed services: ''${failed_services[*]}"
          exit 1
        fi

        echo "All critical services are healthy"
      '';
    };
  };

  systemd.timers.service-health-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/2"; # Every 2 minutes
      Persistent = true;
    };
  };
}
