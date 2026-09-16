_: {
  programs.niri.settings = {
    spawn-at-startup = [
      {command = ["bash" "-c" "wl-paste --type text --watch cliphist store"];}
      {command = ["bash" "-c" "wl-paste --type image --watch cliphist store"];}

      {command = ["wl-clip-persist" "--clipboard" "regular"];}

      {command = ["xwayland-satellite" ":0"];}

      # Required for gvfs backends (trash, NFS) to work in Nemo outside GNOME/Cinnamon.
      {command = ["bash" "-c" "dbus-update-activation-environment --systemd --all"];}

      # Without it, bluetoothd has nothing to answer device_confirm_passkey requests, so
      # devices connect and are immediately dropped; niri doesn't autostart
      # /etc/xdg/autostart entries like GNOME does, so this has to be spawned here.
      {command = ["blueman-applet"];}

      {command = ["systemctl" "--user" "start" "nirinit.service"];}

      {command = ["noctalia"];}

      {command = ["materialgram"];}
      {command = ["vesktop" "--start-minimized"];}

      # --disable-gpu works around a QtWebEngine/NVIDIA GBM bug that corrupts glyph
      # rendering: https://gitlab.com/coolercontrol/coolercontrol/-/issues/526
      {command = ["coolercontrol" "--disable-gpu"];}
    ];
  };
}
