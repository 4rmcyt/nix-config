# modules/services/nixarr/sonarr/default.nix
{
  config,
  pkgs,
  ...
}: {
  systemd.services.sonarr-pg-config = {
    description = "Write Sonarr PostgreSQL config.xml";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    before = ["podman-sonarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "sonarr";
      Group = "sonarr";
    };
    path = [pkgs.xmlstarlet];
    script = ''
      mkdir -p /data/media/.state/nixarr/sonarr
      cfg=/data/media/.state/nixarr/sonarr/config.xml
      if [ ! -f "$cfg" ]; then
        printf '<Config>\n</Config>\n' > "$cfg"
      fi
      PG_PASS=$(cat ${config.sops.secrets.sonarr_db_password.path} | tr -d '\n\r')
      for pair in "Port:8990" "PostgresUser:sonarr" "PostgresPassword:$PG_PASS" "PostgresPort:5432" "PostgresHost:127.0.0.1" "PostgresMainDb:sonarr" "PostgresLogDb:sonarr-log"; do
        key="''${pair%%:*}"
        val="''${pair#*:}"
        if xmlstarlet sel -t -v "count(/Config/$key)" "$cfg" 2>/dev/null | grep -q "^0$"; then
          xmlstarlet ed -L -s /Config -t elem -n "$key" -v "$val" "$cfg"
        else
          xmlstarlet ed -L -u "/Config/$key" -v "$val" "$cfg"
        fi
      done
      chmod 600 "$cfg"
    '';
  };

  virtualisation.oci-containers.containers.sonarr = {
    autoStart = true;
    image = "lscr.io/linuxserver/sonarr:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--env=PUID=${toString config.users.users.sonarr.uid}"
      "--env=PGID=${toString config.users.groups.sonarr.gid}"
      "--env=TZ=${config.my.defaults.timezone}"
    ];
    volumes = [
      "/data/media/.state/nixarr/sonarr:/config"
      "/data/media:/data/media"
      "/data/Downloads:/data/Downloads"
    ];
  };

  systemd.services.podman-sonarr = {
    after = ["data.mount" "sonarr-pg-config.service"];
    requires = ["data.mount" "sonarr-pg-config.service"];
  };
}
