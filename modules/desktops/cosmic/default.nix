{
  pkgs,
  lib,
  inputs,
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
    trusted-public-keys = lib.mkBefore [
      "9lore.cachix.org-1:H2/a1Wlm7VJRfJNNvFbxtLQPYswP3KzXwSI5ROgzGII="
    ];
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

  environment.systemPackages = lib.mkBefore (
    (with pkgs; [
      tasks
      quick-webapps
      cosmic-bg
      cosmic-osd
      cosmic-idle
      cosmic-comp
      cosmic-randr
      cosmic-icons
      cosmic-reader
      cosmic-ext-ctl
      cosmic-applets
      cosmic-protocols
      cosmic-screenshot
      cosmic-ext-tweaks
      cosmic-ext-applet-caffeine
      cosmic-ext-applet-external-monitor-brightness
    ])
  );

  systemd.user.services.cosmic-ext-bg-theme = {
    description = "COSMIC Background Theme Extension";
    documentation = ["man:cosmic-ext-bg-theme(1)"];
    partOf = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${inputs.cosmic-applets-collection.packages.${pkgs.stdenv.hostPlatform.system}.cosmic-ext-bg-theme}/bin/cosmic-ext-bg-theme";
      Restart = "on-failure";
    };
  };
}
