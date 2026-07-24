# modules/services/nixarr/prowlarr/default.nix
{
  config,
  pkgs,
  ...
}: {
  systemd.services.prowlarr-pg-config = {
    description = "Write Prowlarr PostgreSQL config.xml";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    before = ["podman-prowlarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "prowlarr";
      Group = "prowlarr";
    };
    path = [pkgs.xmlstarlet];
    script = ''
      mkdir -p /data/media/.state/nixarr/prowlarr
      cfg=/data/media/.state/nixarr/prowlarr/config.xml
      if [ ! -f "$cfg" ]; then
        printf '<Config>\n</Config>\n' > "$cfg"
      fi
      PG_PASS=$(cat ${config.sops.secrets.prowlarr_db_password.path} | tr -d '\n\r')
      for pair in "PostgresUser:prowlarr" "PostgresPassword:$PG_PASS" "PostgresPort:5432" "PostgresHost:127.0.0.1" "PostgresMainDb:prowlarr" "PostgresLogDb:prowlarr-log"; do
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

  virtualisation.oci-containers.containers.prowlarr = {
    autoStart = true;
    image = "lscr.io/linuxserver/prowlarr:latest";
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--env=PUID=${toString config.users.users.prowlarr.uid}"
      "--env=PGID=${toString config.users.groups.prowlarr.gid}"
      "--env=TZ=${config.my.defaults.timezone}"
    ];
    volumes = [
      "/data/media/.state/nixarr/prowlarr:/config"
    ];
  };

  systemd.services.podman-prowlarr = {
    after = ["data.mount" "prowlarr-pg-config.service"];
    requires = ["data.mount" "prowlarr-pg-config.service"];
  };
}
