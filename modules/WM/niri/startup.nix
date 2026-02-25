_: {
  programs.niri.settings = {
    spawn-at-startup = [
      # Clipboard history daemon
      {command = ["bash" "-c" "wl-paste --type text --watch cliphist store"];}
      {command = ["bash" "-c" "wl-paste --type image --watch cliphist store"];}

      # Clipboard persistence
      {command = ["wl-clip-persist" "--clipboard" "both"];}

      # XWayland support
      {command = ["xwayland-satellite" ":0"];}
    ];
  };
}
