{
  config,
  lib,
  pkgs,
  ...
}: {
  options.roles.desktop = {
    enable = lib.mkEnableOption "desktop role with GUI and user-focused configurations";
  };

  config = lib.mkIf config.roles.desktop.enable {
    # Desktop services
    services = {
      # X Server - Required for XWayland compatibility even on Wayland-first systems
      # Provides X11 app support in Wayland sessions (Plasma 6, GNOME, etc.)
      xserver = {
        enable = lib.mkDefault true;

        # Keyboard layout - can be overridden per host
        xkb = {
          layout = lib.mkDefault "us";
        };

        # Note: Desktop environment (Plasma/GNOME) and display manager (SDDM/GDM)
        # should be configured in individual host configs, not in the role
        # This allows Wayland-first setups while maintaining X11 app compatibility
      };

      # Audio - PipeWire for modern Linux audio
      pipewire = {
        enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        alsa.support32Bit = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
        jack.enable = lib.mkDefault true;
      };

      # Printing (CUPS)
      printing.enable = lib.mkDefault true;

      # Power management for laptops/desktops
      upower.enable = lib.mkDefault true;

      # Bluetooth GUI manager
      blueman.enable = lib.mkDefault true;
    };

    # Hardware
    hardware = {
      bluetooth.enable = lib.mkDefault true;
      pulseaudio.enable = lib.mkDefault false; # Use PipeWire instead
    };

    # Fonts
    fonts = {
      enableDefaultPackages = lib.mkDefault true;
      packages = with pkgs;
        lib.mkDefault [
          noto-fonts
          noto-fonts-emoji
          liberation_ttf
          fira-code
          fira-code-symbols
        ];
    };

    # Desktop-focused security
    security = {
      rtkit.enable = lib.mkDefault true; # For PipeWire
      polkit.enable = lib.mkDefault true;
    };

    # Desktop networking
    networking = {
      networkmanager.enable = lib.mkDefault true;
      firewall.enable = lib.mkDefault true;
    };

    # Desktop-specific system utilities
    # Note: Common packages (git, vim, wget, curl, htop) are in modules/base/common-packages
    # GUI applications should be managed via modules/GUI/ or home-manager
    environment.systemPackages = with pkgs;
      lib.mkDefault [
        # Archive utilities (desktop-specific)
        unzip
        zip

        # File utilities
        file
        tree

        # Hardware inspection tools (desktop-specific)
        pciutils
        usbutils
        lshw
      ];
  };
}
