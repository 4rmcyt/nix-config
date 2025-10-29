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
      # Display manager and desktop environment
      xserver = {
        enable = lib.mkDefault true;
        xkb = {
          layout = lib.mkDefault "us";
        };
      };

      # Audio
      pipewire = {
        enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
        jack.enable = lib.mkDefault true;
      };

      # Printing
      printing.enable = lib.mkDefault true;

      # Power management for laptops/desktops
      upower.enable = lib.mkDefault true;

      # Bluetooth
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
      packages = with pkgs; lib.mkDefault [
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

    # Common desktop packages
    environment.systemPackages = with pkgs;
      lib.mkDefault [
        # Basic utilities
        firefox
        git
        vim
        wget
        curl
        unzip
        zip
        htop
      ];
  };
}
