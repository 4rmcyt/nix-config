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

  # Temporary hash fix for cosmic-files until upstream is updated
  nixpkgs.overlays = [
    (final: prev: {
      cosmic-files = prev.cosmic-files.overrideAttrs (oldAttrs: {
        cargoDeps = oldAttrs.cargoDeps.overrideAttrs (oldDeps: {
          outputHash = "sha256-82DuMGVyZAwEaBbLAIodchtjKMugZTiHOHwsLZAJXz4=";
        });
      });
    })
  ];

  # COSMIC-specific nix settings
  nix.settings = {
    substituters = lib.mkBefore [
      "https://9lore.cachix.org?priority=5"
      "https://cosmic.cachix.org?priority=6"
    ];
    trusted-public-keys = lib.mkBefore [
      "9lore.cachix.org-1:H2/a1Wlm7VJRfJNNvFbxtLQPYswP3KzXwSI5ROgzGII="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];
  };

  # Enable COSMIC desktop
  services = {
    desktopManager.cosmic.enable = true;
    displayManager = {
      autoLogin = {
        enable = true;
        user = "zeev";
      };
      cosmic-greeter.enable = true;
    };
    gnome.gnome-keyring.enable = true;
  };

  # Wayland environment variables
  environment.sessionVariables = lib.mkBefore {
    # Qt Wayland Support
    ELECTRON_FORCE_SAFE_STORAGE_BACKEND = "gnome_libsecret";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";

    # Wayland Support
    CLUTTER_BACKEND = "wayland";
    COSMIC_DATA_CONTROL_ENABLED = 1;
    COSMIC_DISABLE_DIRECT_SCANOUT = 1;
    SDL_VIDEODRIVER = "wayland";

    # iso-codes data for COSMIC apps
    XDG_DATA_DIRS = lib.mkAfter ["${pkgs.isocodes}/share"];
  };

  # Security settings
  security = {
    pam.services.login.enableGnomeKeyring = true;
    polkit.enable = true;
    rtkit.enable = true;
  };

  # XDG Portal for COSMIC
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-cosmic
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  environment.systemPackages = lib.mkBefore (
    with pkgs; [
      adw-gtk3
      cheese
      cosmic-applibrary
      cosmic-applets
      cosmic-bg
      cosmic-comp
      cosmic-ext-applet-caffeine
      cosmic-ext-applet-external-monitor-brightness
      cosmic-ext-calculator
      cosmic-ext-ctl
      cosmic-ext-tweaks
      cosmic-icons
      cosmic-idle
      cosmic-initial-setup
      cosmic-osd
      cosmic-protocols
      cosmic-randr
      cosmic-reader
      cosmic-screenshot
      forecast
      gnome-calendar
      gnome-online-accounts-gtk
      gnome-online-accounts
      isocodes
      libisocodes
      libsecret
      locale
      loupe
      quick-webapps
      seahorse
      tasks
    ]
  );
}
