{
  pkgs,
  lib,
  ...
}: {
  # =================================================================
  # COSMIC Desktop Environment - NixOS Configuration
  # =================================================================

  imports = [
    ../../GUI/flatpak/cosmic
  ];

  # COSMIC-specific nix settings
  nix.settings = {
    substituters = lib.mkBefore ["https://9lore.cachix.org/"];
    trusted-public-keys = lib.mkBefore ["9lore.cachix.org-1:H2/a1Wlm7VJRfJNNvFbxtLQPYswP3KzXwSI5ROgzGII="];
  };

  # Enable COSMIC desktop
  services = {
    desktopManager.cosmic.enable = true;
    displayManager = {
      cosmic-greeter.enable = true;
      autoLogin = {
        enable = true;
        user = "zeev";
      };
    };
  };

  # Wayland environment variables
  environment.sessionVariables = {
    # Wayland Support
    COSMIC_DATA_CONTROL_ENABLED = 1;
    NIXOS_OZONE_WL = "1";
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";

    # Browser Optimization
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  # Security settings
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # XDG Portal for COSMIC
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-cosmic
    ];
  };
  # systemd.packages = [pkgs.observatory];
  # systemd.services.monitord.wantedBy = ["multi-user.target"];
}
