_: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # ============================================
      # THEME & APPEARANCE - DMS Compatible
      # ============================================
      # DMS 1.0.x: Use DankMaterialShell generated colors
      # Reference: https://danklinux.com/docs/dankmaterialshell/application-themes#ghostty
      config-file = "~/.config/ghostty/config-dankcolors"; # DMS-generated theme (synced with wallpaper)
      # Note: In DMS 1.2, this will become: theme = "dankcolors"

      # Background effects - MUST come AFTER config-file to override DMS's solid background
      # Use transparent background instead of DMS's opaque #19120c
      background = "#19120ceb"; # Same color but with alpha channel (eb = 92% opacity)
      background-blur-radius = 25; # Reduced for better niri performance

      # Font configuration
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      font-feature = ["+liga"]; # Enable ligatures for modern look

      # ============================================
      # WINDOW BEHAVIOR - Niri Optimized
      # ============================================
      window-theme = "dark";
      gtk-titlebar = false; # Let niri handle decorations
      gtk-single-instance = false; # Multiple windows support
      window-decoration = false; # Use niri's borders and focus ring
      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;

      # Tabs
      window-show-tab-bar = "never";

      # ============================================
      # CURSOR
      # ============================================
      cursor-style = "block";
      cursor-style-blink = true;

      # ============================================
      # SHELL INTEGRATION
      # ============================================
      shell-integration = "zsh";
      shell-integration-features = "sudo,cursor,no-title";

      # ============================================
      # PERFORMANCE - Nvidia + Niri
      # ============================================
      # renderer option removed - Ghostty auto-detects renderer

      # ============================================
      # MOUSE & CLIPBOARD - Wayland
      # ============================================
      mouse-hide-while-typing = true;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-trim-trailing-spaces = true;
      copy-on-select = "clipboard"; # Use Wayland clipboard

      # ============================================
      # KEYBINDINGS - DMS Compatible
      # ============================================
      # Note: Avoid conflicts with DMS shortcuts
      keybind = [
        # Standard terminal operations
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+w=close_surface"
        "ctrl+shift+n=new_window"

        # Font size (avoid Super+ conflicts with DMS)
        "ctrl+plus=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+equal=reset_font_size"

        # Tab navigation
        "ctrl+tab=next_tab"
        "ctrl+shift+tab=previous_tab"
        "alt+1=goto_tab:1"
        "alt+2=goto_tab:2"
        "alt+3=goto_tab:3"
        "alt+4=goto_tab:4"
        "alt+5=goto_tab:5"

        # Fullscreen
        "f11=toggle_fullscreen"
      ];

      # ============================================
      # ADVANCED
      # ============================================
      confirm-close-surface = false;
      quit-after-last-window-closed = false; # Keep running in background
      window-save-state = "always"; # Restore windows with niri

      # Link handling
      link-url = true;

      # Scrollback
      scrollback-limit = 10000;

      # Visual improvements
      minimum-contrast = 1.15;
      unfocused-split-opacity = 0.85;
    };
  };
}
