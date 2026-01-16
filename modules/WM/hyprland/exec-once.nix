_: {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # ============================================
      # XDG PORTAL SERVICES
      # ============================================

      # Ensure portal services are running for xdg-open, file dialogs, etc.
      "systemctl --user start xdg-desktop-portal-gtk.service"
      "systemctl --user restart xdg-desktop-portal.service"

      # ============================================
      # SESSION MANAGEMENT
      # ============================================

      # Hyprland session manager
      # "hyprsession" moved to hyprsession.nix

      # ============================================
      # DMS CORE SERVICES
      # ============================================

      # Start DankMaterialShell
      "systemctl --user start dms.service"

      # ============================================
      # CLIPBOARD MANAGEMENT
      # ============================================

      # Clipboard history daemon (if DMS clipboard is enabled)
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"

      # Clipboard persistence
      "wl-clip-persist --clipboard both"

      # ============================================
      # XWAYLAND SUPPORT
      # ============================================

      # XWayland satellite for X11 app compatibility
      "xwayland-satellite :0"

      # ============================================
      # POLKIT AUTHENTICATION
      # ============================================

      # Polkit authentication agent (if DMS_DISABLE_POLKIT is set)
      # Uncomment if you're using an alternative polkit agent
      # "polkit-kde-authentication-agent-1"

      # ============================================
      # IDLE & POWER MANAGEMENT
      # ============================================

      # Idle daemon with screen locking
      # "swayidle -w timeout 300 'swaylock' timeout 600 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' before-sleep 'swaylock'"
    ];
  };
}
