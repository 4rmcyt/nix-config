_: {
  wayland.windowManager.hyprland.settings = {
    # ============================================
    # INPUT
    # ============================================
    input = {
      kb_layout = "us";
      kb_options = "grp:alt_caps_toggle";
      numlock_by_default = true;
      repeat_delay = 300;
      follow_mouse = 0;
      float_switch_override_focus = 0;
      mouse_refocus = 0;
      sensitivity = 0;

      touchpad = {
        natural_scroll = true;
      };
    };

    # ============================================
    # GENERAL
    # ============================================
    general = {
      "$mainMod" = "SUPER";
      layout = "dwindle";
      gaps_in = 6;
      gaps_out = 12;
      border_size = 2;
      "col.active_border" = "rgb(98971A) rgb(CC241D) 45deg";
      "col.inactive_border" = "0x00000000";
      no_border_on_floating = false;
    };

    # ============================================
    # MISCELLANEOUS
    # ============================================
    misc = {
      disable_hyprland_logo = true;
      always_follow_on_dnd = true;
      layers_hog_keyboard_focus = true;
      animate_manual_resizes = false;
      enable_swallow = true;
      focus_on_activate = true;
      new_window_takes_over_fullscreen = 2;
      middle_click_paste = false;
      vfr = true;  # Variable Frame Rate (power saving)
      vrr = 1;     # Variable Refresh Rate (Nvidia VRR/G-Sync)
    };

    # ============================================
    # RENDER (Nvidia Optimizations)
    # ============================================
    render = {
      explicit_sync = 2;      # Fixes screen tearing on Nvidia
      explicit_sync_kms = 2;  # KMS explicit sync
    };

    # ============================================
    # CURSOR (Nvidia Compatibility)
    # ============================================
    cursor = {
      no_hardware_cursors = true;  # Required for Nvidia
      allow_dumb_copy = true;
    };

    # ============================================
    # DWINDLE LAYOUT
    # ============================================
    dwindle = {
      force_split = 2;
      special_scale_factor = 1.0;
      split_width_multiplier = 1.0;
      use_active_for_splits = true;
      pseudotile = "yes";
      preserve_split = "yes";
    };

    # ============================================
    # MASTER LAYOUT
    # ============================================
    master = {
      new_status = "master";
      special_scale_factor = 1;
    };

    # ============================================
    # DECORATION
    # ============================================
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
        new_optimizations = true;  # Performance optimization
        xray = true;               # See through floating windows
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

    # ============================================
    # ANIMATIONS
    # ============================================
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

    # ============================================
    # XWAYLAND
    # ============================================
    xwayland = {
      force_zero_scaling = true;
    };
  };
}
