_: {
  # MangoWC autostart configuration
  # Note: MangoWC uses dwl/wlroots-style configuration

  # Create autostart script for MangoWC
  home.file.".config/mangowc/autostart.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      # ============================================
      # ENVIRONMENT EXPORT (Required for MangoWC)
      # ============================================
      # Export environment for systemd user services
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      # ============================================
      # CLIPBOARD MANAGEMENT
      # ============================================
      # Clipboard history daemon (if DMS clipboard is enabled)
      wl-paste --type text --watch cliphist store &
      wl-paste --type image --watch cliphist store &

      # Clipboard persistence
      wl-clip-persist --clipboard both &

      # ============================================
      # XWAYLAND SUPPORT
      # ============================================
      # XWayland satellite for X11 app compatibility
      xwayland-satellite :0 &

      # ============================================
      # SESSION TARGET
      # ============================================
      # Start MangoWC session target (this will start DMS)
      systemctl --user start mango-session.target
    '';
  };
}
