{pkgs, ...}: {
  imports = [
    ../../GUI/flatpak/kde
  ];

  # KDE system packages
  environment.systemPackages = with pkgs; [
    # Core Plasma components that need system-wide availability
    kdePackages.discover
    kdePackages.systemsettings
    kdePackages.plasma-pa
    kdePackages.sddm-kcm
    kdePackages.partitionmanager
    kdePackages.ksystemlog
    kdePackages.kio-extras
    kdePackages.signon-kwallet-extension
    kdePackages.qtwayland
    kdePackages.applet-window-buttons6
    kdePackages.wayland
    kdePackages.wayland-protocols
    kdePackages.plasma-wayland-protocols
    kdePackages.kwayland
    kdePackages.qgpgme
    kdePackages.sweeper
    kdePackages.kwalletmanager
    kdePackages.kwallet-pam
    kdePackages.kwallet
  ];

  # Essential system services for KDE Plasma
  services = {
    desktopManager.plasma6.enable = true;

    displayManager = {
      autoLogin = {
        enable = true;
        user = "zeev";
      };

      sddm = {
        enable = true;
        autoNumlock = true;
        enableHidpi = true;
        theme = "breeze";
        wayland.compositor = "kwin";
        wayland.enable = true;
      };
    };
  };

  # Essential system security services
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # XDG portal for Flatpak and sandboxed apps
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
    # Fix portal registration issues
    xdgOpenUsePortal = true;
    config = {
      common = {
        default = ["kde"];
      };
      kde = {
        default = ["kde" "gtk"];
      };
    };
  };

  # Enable dbus for proper portal communication
  services.dbus.enable = true;
}
