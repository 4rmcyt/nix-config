_: {
  # ============================================
  # NIRI MONITOR CONFIGURATION
  # ============================================

  programs.niri.settings = {
    outputs = {
      # Left Monitor: DP-4
      "DP-4" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 60.0;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 2.0;
        # VRR is enabled globally via layout settings
      };

      # Right Monitor: DP-5
      "DP-5" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 60.0;
        };
        position = {
          x = 1920; # Effective width after 2.0x scaling: 3840÷2 = 1920
          y = 0;
        };
        scale = 2.0;
      };
    };
  };

  # Monitor configuration documentation
  home.file.".config/niri/monitors.md".text = ''
    # Niri Monitor Configuration Guide

    ## Current Setup
    You have two 4K monitors (3840x2160 @ 60Hz) with 2x scaling:
    - **DP-4**: Primary monitor at position (0,0)
    - **DP-5**: Secondary monitor at position (1920,0)

    ## Niri Output Configuration Structure
    ```nix
    outputs = {
      "OUTPUT-NAME" = {
        mode = { width = 3840; height = 2160; refresh = 60.0; };
        position = { x = 0; y = 0; };
        scale = 2.0;
      };
    };
    ```

    ### Parameters Explained:
    - **mode.width/height**: Resolution in pixels
    - **mode.refresh**: Refresh rate in Hz (floating point)
    - **position.x/y**: Monitor position (calculated after scaling)
    - **scale**: HiDPI scaling factor

    ## Finding Monitor Names
    Use `niri msg outputs` to list outputs:
    ```bash
    niri msg outputs
    ```

    Or check with wlr-randr:
    ```bash
    wlr-randr
    ```

    ## Position Calculation
    When using scaling, positions are in **logical pixels** (after scaling):
    - DP-4 physical: 3840x2160 at 2x scale = 1920x1080 logical
    - DP-5 position: starts at x=1920 (end of DP-4 logical width)

    ## VRR/Adaptive Sync
    Niri supports VRR globally. Check if enabled in your GPU settings.

    ## Color Depth
    Niri automatically uses the best available color depth supported by:
    - Your GPU
    - Your display
    - Your cable (DisplayPort/HDMI)

    ## Changing Configuration
    Edit the monitor settings in:
    ```
    ~/.config/nix-config/modules/WM/niri/monitors.nix
    ```

    ## Additional Monitor Options

    ### Transform (Rotation)
    ```nix
    outputs."DP-1".transform = {
      # Supported: "normal", "90", "180", "270"
      # Or with flipping: "flipped", "flipped-90", "flipped-180", "flipped-270"
    };
    ```

    ### Disable Output
    ```nix
    outputs."eDP-1".off = true;
    ```

    ### Variable Refresh Rate
    ```nix
    outputs."DP-4".variable-refresh-rate = true;
    ```

    ## Runtime Changes
    Change monitor settings without reloading:
    ```bash
    niri msg output DP-4 mode 3840x2160@60
    niri msg output DP-4 scale 2.0
    niri msg output DP-4 position 0 0
    ```

    ## Layout Settings
    Your column layout settings (from layout configuration):
    - **default-column-width**: 0.5 (50% of screen width)
    - **preset-column-widths**: 33%, 50%, 66%
    - **gaps**: 5px between windows
    - **center-focused-column**: never

    ## Multi-Monitor Workflow
    - Windows can be moved between monitors with keybindings
    - Each monitor maintains its own window layout
    - Focus follows between monitors seamlessly

    ## Troubleshooting
    - If monitors aren't detected: `niri msg outputs`
    - Verify cable supports 4K@60Hz
    - Check GPU driver supports your resolution
    - Test with: `wlr-randr --output DP-4 --mode 3840x2160@60`
  '';

  # Runtime configuration file (sourced by niri if exists)
  home.file.".config/niri/monitors.kdl".text = ''
    // Niri Monitor Configuration (KDL format)
    // This file is managed by home-manager
    // Main configuration is in the Nix config

    // The configuration is applied through home-manager's niri settings
    // This file is for reference or manual runtime testing

    // To test monitor changes at runtime, use:
    // niri msg output DP-4 mode 3840x2160@60
    // niri msg output DP-4 scale 2.0
    // niri msg output DP-4 position 0 0
  '';
}
