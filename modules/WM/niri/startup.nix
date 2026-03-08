{pkgs, ...}: {
  programs.niri.settings = {
    spawn-at-startup = [
      # Polkit authentication agent (required for privileged ops e.g. flatpak installs)
      {command = ["${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"];}

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

      # Session manager (started via systemd for lifecycle management)
      {command = ["systemctl" "--user" "start" "nirinit.service"];}
    ];
  };
}
