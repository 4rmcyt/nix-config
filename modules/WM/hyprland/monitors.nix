_: {
  # ============================================
  # HYPRLAND MONITOR CONFIGURATION
  # ============================================

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-4,3840x2160@60,0x0,2.0,bitdepth,8,vrr,1"
      "DP-5,3840x2160@60,1920x0,2.0,bitdepth,8,vrr,1"
    ];
  };

  # Monitor configuration documentation
  home.file.".config/hypr/monitors.md".text = ''
    # Hyprland Monitor Configuration Guide

    ## Current Setup
    You have two 4K monitors (3840x2160 @ 60Hz) with 2x scaling:
    - **DP-4**: Primary monitor at position (0,0)
    - **DP-5**: Secondary monitor at position (1920,0)

    ## Monitor Syntax
    ```
    monitor=name,resolution@refreshrate,position,scale,additional_params
    ```

    ### Parameters Explained:
    - **name**: Output identifier (e.g., DP-4, HDMI-A-1)
    - **resolution@refreshrate**: e.g., 3840x2160@60
    - **position**: X and Y offset (e.g., 0x0, 1920x0)
    - **scale**: Scaling factor (2.0 for HiDPI)
    - **bitdepth**: Color depth (8 or 10)
    - **vrr**: Variable refresh rate (0 or 1)

    ## Finding Monitor Names
    Use hyprctl to list outputs:
    ```bash
    hyprctl monitors
    ```

    ## VRR (Variable Refresh Rate)
    Your monitors have VRR enabled (`vrr,1`) for:
    - Smoother gaming experience
    - Adaptive sync support
    - Reduced screen tearing

    ## 10-bit Color
    Both monitors use 10-bit color depth (`bitdepth,10`) for:
    - Better color accuracy
    - HDR support preparation
    - Smoother gradients

    ## Changing Configuration
    Edit the monitor settings in:
    ```
    ~/.config/nix-config/modules/WM/hyprland/monitors.nix
    ```

    ## Additional Monitor Options
    - **transform**: Rotate display (0, 1, 2, 3 for 0°, 90°, 180°, 270°)
    - **mirror**: Mirror another display
    - **disabled**: Disable a monitor

    ### Examples:
    ```
    # Rotate display 90 degrees
    monitor=DP-1,3840x2160@60,0x0,2.0,transform,1

    # Disable internal display
    monitor=eDP-1,disable

    # Mirror display
    monitor=HDMI-A-1,3840x2160@60,0x0,2.0,mirror,DP-4
    ```

    ## HDR Support
    HDR is enabled per-window via window rules (see windowrules.nix):
    - Jellyfin Desktop
    - Chromium browser
    - Other media applications

    ## Runtime Changes
    Change monitor settings without reloading:
    ```bash
    hyprctl keyword monitor "DP-4,3840x2160@60,0x0,2.0,bitdepth,10,vrr,1"
    ```

    ## Troubleshooting
    - If monitors aren't detected: `hyprctl monitors all`
    - Check cable/connection supports 4K@60Hz with 10-bit
    - VRR requires compatible display and GPU
  '';

  # Per-monitor configuration overrides (optional)
  home.file.".config/hypr/monitors.conf".text = ''
    # Hyprland Monitor Configuration
    # This file is managed by home-manager but can be used for runtime overrides

    # Main monitor configuration is in the Nix config
    # Add temporary/testing monitor configs here:

    # Example:
    # monitor=DP-4,3840x2160@60,0x0,2.0,bitdepth,10,vrr,1
    # monitor=DP-5,3840x2160@60,1920x0,2.0,bitdepth,10,vrr,1
  '';
}
