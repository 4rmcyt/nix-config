# modules/services/nixarr/radarr/default.nix
{
  config,
  pkgs,
  ...
}: {
  systemd.services.radarr-pg-config = {
    description = "Write Radarr PostgreSQL config.xml";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    before = ["podman-radarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "radarr";
      Group = "radarr";
    };
    path = [pkgs.xmlstarlet];
    script = ''
      mkdir -p /data/media/.state/nixarr/radarr
      cfg=/data/media/.state/nixarr/radarr/config.xml
      if [ ! -f "$cfg" ]; then
        printf '<Config>\n</Config>\n' > "$cfg"
      fi
      PG_PASS=$(cat ${config.sops.secrets.radarr_db_password.path} | tr -d '\n\r')
      for pair in "PostgresUser:radarr" "PostgresPassword:$PG_PASS" "PostgresPort:5432" "PostgresHost:127.0.0.1" "PostgresMainDb:radarr" "PostgresLogDb:radarr-log"; do
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

  virtualisation.oci-containers.containers.radarr = {
    autoStart = true;
    image = "lscr.io/linuxserver/radarr:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--env=PUID=${toString config.users.users.radarr.uid}"
      "--env=PGID=${toString config.users.groups.radarr.gid}"
      "--env=TZ=${config.my.defaults.timezone}"
    ];
    volumes = [
      "/data/media/.state/nixarr/radarr:/config"
      "/data/media:/data/media"
      "/data/Downloads:/data/Downloads"
    ];
  };

  systemd.services.podman-radarr = {
    after = ["data.mount" "radarr-pg-config.service"];
    requires = ["data.mount" "radarr-pg-config.service"];
  };
}
