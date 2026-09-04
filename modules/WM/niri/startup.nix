_: {
  programs.niri.settings = {
    spawn-at-startup = [
      # Clipboard history daemon
      {command = ["bash" "-c" "wl-paste --type text --watch cliphist store"];}
      {command = ["bash" "-c" "wl-paste --type image --watch cliphist store"];}

      # Clipboard persistence
      {command = ["wl-clip-persist" "--clipboard" "regular"];}

      # XWayland support
      {command = ["xwayland-satellite" ":0"];}

      # Propagate PAM environment (GIO_EXTRA_MODULES, etc.) into D-Bus/systemd user session
      # Required for gvfs backends (trash, NFS) to work in Nemo outside GNOME/Cinnamon
      {command = ["bash" "-c" "dbus-update-activation-environment --systemd --all"];}

      # Bluetooth pairing agent — without it bluetoothd has nothing to answer
      # device_confirm_passkey requests, so devices connect and are
      # immediately dropped. niri (unlike GNOME) doesn't autostart
      # /etc/xdg/autostart .desktop entries, so this has to be spawned here.
      {command = ["blueman-applet"];}

      # Session manager (started via systemd for lifecycle management)
      {command = ["systemctl" "--user" "start" "nirinit.service"];}

      # Desktop shell
      {command = ["noctalia"];}

      # Messaging apps
      {command = ["materialgram"];}
      {command = ["vesktop" "--start-minimized"];}

      # Fan/pump curve control (nct6687 SuperIO + AMD GPU/liquidctl).
      # No CLI flag for minimize-to-tray exists (unlike corectrl) — enable
      # "Start in Tray" / "Close to Tray" once in the app's own Settings.
      # --disable-gpu works around a QtWebEngine/NVIDIA-proprietary GBM bug
      # that corrupts glyph rendering (falls back to a broken Vulkan path):
      # https://gitlab.com/coolercontrol/coolercontrol/-/issues/526
      {command = ["coolercontrol" "--disable-gpu"];}
    ];
  };
}
