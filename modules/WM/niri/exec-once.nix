{lib, ...}: {
  programs.niri.settings = {
    # Use mkForce to completely override DMS module's spawn-at-startup
    # This prevents the DMS module from adding "dms run" despite enableSpawn = false
    # NOTE: We do NOT spawn DMS here because systemd.enable = true auto-starts it
    spawn-at-startup = lib.mkForce [
      # ============================================
      # CLIPBOARD MANAGEMENT
      # ============================================

      {
        command = [
          "wl-paste"
          "--type"
          "text"
          "--watch"
          "cliphist"
          "store"
        ];
      }

      {
        command = [
          "wl-paste"
          "--type"
          "image"
          "--watch"
          "cliphist"
          "store"
        ];
      }

      # Clipboard persistence
      {
        command = [
          "wl-clip-persist"
          "--clipboard"
          "both"
        ];
      }

      # ============================================
      # XWAYLAND SUPPORT
      # ============================================

      # XWayland satellite for X11 app compatibility
      {
        command = [
          "xwayland-satellite"
          ":0"
        ];
      }

      # ============================================
      # POLKIT AUTHENTICATION
      # ============================================

      # Polkit authentication agent (if DMS_DISABLE_POLKIT is set)
      # Uncomment if you're using an alternative polkit agent
      # {
      #   command = [
      #     "polkit-kde-authentication-agent-1"
      #   ];
      # }

      # ============================================
      # PORTAL INTEGRATION
      # ============================================

      # XDG Desktop Portal (handled by systemd usually)
      # {
      #   command = [
      #     "dbus-update-activation-environment"
      #     "--systemd"
      #     "WAYLAND_DISPLAY"
      #     "XDG_CURRENT_DESKTOP"
      #   ];
      # }

      # ============================================
      # NOTIFICATION DAEMON
      # ============================================

      # Notification daemon (if not using DMS notifications)
      # {
      #   command = [
      #     "swaync"
      #   ];
      # }

      # ============================================
      # IDLE & POWER MANAGEMENT
      # ============================================

      # Idle daemon with screen locking
      # {
      #   command = [
      #     "swayidle"
      #     "-w"
      #     "timeout"
      #     "300"
      #     "swaylock"
      #     "timeout"
      #     "600"
      #     "niri msg action power-off-monitors"
      #     "resume"
      #     "niri msg action power-on-monitors"
      #     "before-sleep"
      #     "swaylock"
      #   ];
      # }

      # ============================================
      # USER APPLICATIONS
      # ============================================

      # Background apps you want to auto-start
      # {
      #   command = ["discord"];
      # }

      # {
      #   command = ["element-desktop"];
      # }
    ];
  };
}
