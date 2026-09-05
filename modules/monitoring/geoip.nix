{pkgs, ...}: {
  # GeoIP Database (db-ip.com, no account required)
  systemd.tmpfiles.rules = [
    "d /var/lib/geoip 0755 root root -"
  ];

  systemd.services.geoip-update = {
    description = "Download db-ip city MMDB for Alloy geoip enrichment";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "geoip-update" ''
        set -euo pipefail
        DEST=/var/lib/geoip/city.mmdb
        YEAR_MONTH=$(${pkgs.coreutils}/bin/date +%Y-%m)
        URL="https://download.db-ip.com/free/dbip-city-lite-''${YEAR_MONTH}.mmdb.gz"
        TMP=$(${pkgs.coreutils}/bin/mktemp)
        trap 'rm -f "$TMP" "$TMP.gz"' EXIT
        ${pkgs.curl}/bin/curl -fsSL "$URL" -o "$TMP.gz"
        ${pkgs.gzip}/bin/gunzip -c "$TMP.gz" > "$TMP"
        ${pkgs.coreutils}/bin/install -m 0644 "$TMP" "$DEST"
        echo "GeoIP DB updated from $URL: $(${pkgs.coreutils}/bin/stat -c %s $DEST) bytes"
      '';
    };
  };

  systemd.timers.geoip-update = {
    description = "Monthly GeoIP DB update";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
