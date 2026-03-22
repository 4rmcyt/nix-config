{pkgs, ...}: {
  programs.niri.settings = {
    spawn-at-startup = [
      # Clipboard history daemon
      {command = ["bash" "-c" "wl-paste --type text --watch cliphist store"];}
      {command = ["bash" "-c" "wl-paste --type image --watch cliphist store"];}

      # Clipboard persistence
      {command = ["wl-clip-persist" "--clipboard" "both"];}

      # XWayland support
      {command = ["xwayland-satellite" ":0"];}

      # Propagate PAM environment (GIO_EXTRA_MODULES, etc.) into D-Bus/systemd user session
      # Required for gvfs backends (trash, NFS) to work in Nautilus outside GNOME
      {command = ["bash" "-c" "dbus-update-activation-environment --systemd --all"];}

      # Kill any stray polkit agents (e.g. polkit-gnome) before DMS registers its own
      {command = ["bash" "-c" "pkill -f polkit-gnome-authentication-agent || true"];}

      # Session manager (started via systemd for lifecycle management)
      {command = ["systemctl" "--user" "start" "nirinit.service"];}

      # DMS — log to ~/.local/state/dms/dms.log (rotated by dms-logrotate.timer)
      {command = ["bash" "-c" "exec dms run >> ~/.local/state/dms/dms.log 2>&1"];}
    ];
  };

  # Ensure DMS log directory exists at login
  systemd.user.tmpfiles.rules = [
    "d %h/.local/state/dms 0755 - - - -"
  ];

  # Rotate DMS log daily: truncate after 10MB, keep 3 compressed rotations
  systemd.user.services.dms-logrotate = {
    Unit.Description = "Rotate DMS log";
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "dms-logrotate" ''
        log="$HOME/.local/state/dms/dms.log"
        [ -f "$log" ] || exit 0
        size=$(stat -c%s "$log" 2>/dev/null || echo 0)
        [ "$size" -gt 10485760 ] || exit 0
        [ -f "$log.2.gz" ] && mv "$log.2.gz" "$log.3.gz"
        [ -f "$log.1.gz" ] && mv "$log.1.gz" "$log.2.gz"
        gzip -c "$log" > "$log.1.gz"
        : > "$log"
      '';
    };
  };

  systemd.user.timers.dms-logrotate = {
    Unit.Description = "Daily DMS log rotation";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
