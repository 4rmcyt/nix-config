_: {
  # ============================================
  # MANGOWC MONITOR CONFIGURATION
  # ============================================
  # MangoWC uses monitorrule syntax for monitor configuration
  # Syntax: monitorrule=name,mfact,nmaster,layout,transform,scale,x,y,width,height,refreshrate

  # Monitor configuration file for MangoWC
  home.file.".config/mangowc/monitors.conf".text = ''
    # MangoWC Monitor Configuration
    # Generated from NixOS configuration

    # ============================================
    # DUAL 4K MONITORS @ 60Hz (matching Hyprland/Niri setup)
    # ============================================

    # Primary Monitor: DP-4
    # - Resolution: 3840x2160 @ 60Hz
    # - Position: 0,0 (left monitor)
    # - Scale: 2.0 (for HiDPI)
    # - Layout: tile (default tiling layout)
    # - mfact: 0.5 (50% master area, matching niri's 0.5 proportion)
    # - nmaster: 1 (one window in master by default)
    monitorrule=DP-4,0.5,1,tile,0,2,0,0,3840,2160,60

    # Secondary Monitor: DP-5
    # - Resolution: 3840x2160 @ 60Hz
    # - Position: 1920,0 (right of DP-4, considering 2x scale = 1920px effective width)
    # - Scale: 2.0 (for HiDPI)
    # - Layout: tile (default tiling layout)
    # - mfact: 0.5 (50% master area)
    # - nmaster: 1 (one window in master by default)
    monitorrule=DP-5,0.5,1,tile,0,2,1920,0,3840,2160,60

    # ============================================
    # ADDITIONAL SETTINGS
    # ============================================

    # Enable VRR (Variable Refresh Rate) for gaming
    # Note: This might need to be set per-monitor or globally in main config
    # vrr=1

    # Allow tearing for gaming windows (low latency)
    # allow_tearing=1
  '';

  # Documentation for monitor configuration
  home.file.".config/mangowc/monitors.md".text = ''
    # MangoWC Monitor Configuration Guide

    ## Current Setup
    You have two 4K monitors (3840x2160 @ 60Hz) with 2x scaling:
    - **DP-4**: Primary monitor at position (0,0)
    - **DP-5**: Secondary monitor at position (1920,0)

    ## Monitor Rule Syntax
    ```
    monitorrule=name,mfact,nmaster,layout,transform,scale,x,y,width,height,refreshrate
    ```

    ### Parameters Explained:
    - **name**: Output identifier (find with `wlr-randr`)
    - **mfact**: Master area fraction (0.5 = 50%)
    - **nmaster**: Number of windows in master area
    - **layout**: Default layout (`tile`, `scroller`, `monocle`, `deck`)
    - **transform**: Rotation (0=normal, 1=90°, 2=180°, 3=270°, 4-7=flipped)
    - **scale**: UI scaling factor (2.0 for HiDPI)
    - **x,y**: Monitor position (never use negative values!)
    - **width,height**: Resolution in pixels
    - **refreshrate**: Refresh rate in Hz

    ## Finding Monitor Names
    Use `wlr-randr` to list available outputs:
    ```bash
    wlr-randr
    ```

    ## Adjusting Layout
    To change the default layout per monitor, modify the 4th parameter:
    - `tile` - Standard master/stack tiling
    - `scroller` - Scrolling column layout (like niri)
    - `monocle` - Full-screen single window
    - `deck` - Stack layout

    ## VRR/Adaptive Sync
    Variable refresh rate is configured globally or per-window.
    Add to main config: `vrr=1`

    ## Gaming Performance
    Enable frame tearing for lower latency:
    ```
    allow_tearing=1
    ```

    ## Monitor Power Control
    Disable/enable monitors dynamically:
    ```bash
    mmsg -d disable_monitor,DP-4
    mmsg -d enable_monitor,DP-4
    ```

    ## Important Notes
    - **Never use negative coordinates** - XWayland will break!
    - Always position monitors starting from (0,0)
    - Consider effective width when scaling (3840÷2 = 1920px)
    - The `mfact=0.5` matches your niri configuration (50% default width)
  '';
}
