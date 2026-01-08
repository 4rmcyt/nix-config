{pkgs, ...}: {
  # ============================================
  # MODULE IMPORTS
  # ============================================
  imports = [
    # Core Hyprland Configuration
    ./binds.nix
    ./windowrules.nix
    ./exec-once.nix

    # Lock & Security
    ./hyprlock.nix
    ./swaylock.nix

    # UI Components
    ./waybar
    ./swaync
    ./launcher
    ./wlogout.nix

    # Utilities
    ./waypaper
    ./swayosd.nix

    # System Integration
    ./xdg-mimes.nix
    ./gtk.nix
  ];

  home.sessionVariables = {
    # Wayland/Ozone
    NIXOS_OZONE_WL = 1;
    GDK_BACKEND = "wayland,x11";
    ANKI_WAYLAND = 1;
    MOZ_ENABLE_WAYLAND = 1;
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    # Nvidia-specific (hybrid AMD+Nvidia setup)
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";

    # VRR/G-Sync - Enable for Nvidia
    __GL_GSYNC_ALLOWED = 1;
    __GL_VRR_ALLOWED = 1;

    # Qt
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
    DISABLE_QT5_COMPAT = 0;

    # WLR
    WLR_RENDERER = "vulkan";

    # Utilities
    DIRENV_LOG_FORMAT = "";
    GTK_THEME = "Kanagawa-B";
    GRIMBLAST_HIDE_CURSOR = 0;
  };

  # ============================================
  # HYPRLAND PACKAGES
  # ============================================
  home.packages = with pkgs; [
    # Core Wayland/Hyprland Tools
    grim # Screenshot utility
    grimblast # Screenshot wrapper
    hyprpaper # Wallpaper daemon
    hyprpicker # Color picker
    hyprsunset # Blue light filter
    slurp # Region selector
    swayosd # OSD daemon
    swww # Animated wallpaper daemon
    wf-recorder # Screen recorder
    wlogout # Logout menu

    # Clipboard Management
    cliphist # Clipboard history
    wl-clip-persist # Clipboard persistence

    # Display & System
    direnv # Environment loader
    glib # System library
    nwg-displays # Display configuration
    wayland # Wayland library

    # File Manager & Applications
    cosmic-store
    kdePackages.ark # Archive manager
    kdePackages.dolphin # File manager
    kdePackages.gwenview # Image viewer
    kdePackages.kate # Text editor
    kdePackages.okular # PDF viewer
  ];

  # ============================================
  # SYSTEMD INTEGRATION
  # ============================================
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    xwayland = {
      enable = true;
    };

    systemd.enable = true;

    settings = {
      monitor = [
        "DP-4,3840x2160@59.997,0x0,2,bitdepth,10"
        "DP-5,3840x2160@59.997,1920x0,2,bitdepth,10"
      ];

      input = {
        kb_layout = "us";
        kb_options = "grp:alt_caps_toggle";
        numlock_by_default = true;
        repeat_delay = 300;
        follow_mouse = 0;
        float_switch_override_focus = 0;
        mouse_refocus = 0;
        sensitivity = 0;
      };

      "$mod" = "SUPER";

      general = {
        layout = "dwindle";
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "rgb(98971A) rgb(CC241D) 45deg";
        "col.inactive_border" = "0x00000000";
      };

      misc = {
        disable_hyprland_logo = true;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = false;
        enable_swallow = true;
        focus_on_activate = true;
        middle_click_paste = false;
        vfr = true; # Variable Frame Rate (power saving)
        vrr = 1; # Variable Refresh Rate (Nvidia VRR/G-Sync)
      };

      cursor = {
        no_hardware_cursors = true; # Required for Nvidia
      };
      dwindle = {
        force_split = 2;
        special_scale_factor = 1.0;
        split_width_multiplier = 1.0;
        use_active_for_splits = true;
        pseudotile = "yes";
        preserve_split = "yes";
      };

      master = {
        new_status = "master";
        special_scale_factor = 1;
      };

      decoration = {
        rounding = 0;

        blur = {
          enabled = true;
          size = 3;
          passes = 2;
          brightness = 1;
          contrast = 1.4;
          ignore_opacity = true;
          noise = 0;
          new_optimizations = true; # Performance optimization
          xray = true; # See through floating windows
        };

        shadow = {
          enabled = true;
          ignore_window = true;
          offset = "0 2";
          range = 20;
          render_power = 3;
          color = "rgba(00000055)";
        };
      };

      animations = {
        enabled = true;

        bezier = [
          "fluent_decel, 0, 0.2, 0.4, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "fade_curve, 0, 0.55, 0.45, 1"
        ];

        animation = [
          # Windows
          "windowsIn, 1, 4, easeOutCubic, popin 20%"
          "windowsOut, 1, 4, fluent_decel, popin 80%"
          "windowsMove, 1, 2, fluent_decel, slide"

          # Fade
          "fadeIn, 1, 3, fade_curve"
          "fadeOut, 1, 3, fade_curve"
          "fadeSwitch, 0, 1, easeOutCirc"
          "fadeShadow, 1, 10, easeOutCirc"
          "fadeDim, 1, 4, fluent_decel"

          # Workspaces
          "workspaces, 1, 4, easeOutCubic, fade"
        ];
      };
    };

    extraConfig = ''
      # hyprlang noerror true
        source = ~/.config/hypr/monitors.conf
        source = ~/.config/hypr/workspaces.conf
      # hyprlang noerror false
    '';
  };
}
