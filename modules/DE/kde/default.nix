{pkgs, ...}: {
  imports = [
    ../../GUI/flatpak/kde
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
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
    };
  };

  # Enable dbus for proper portal communication
  services.dbus.enable = true;

  # Enable GNOME keyring for secret portal
  services.gnome.gnome-keyring.enable = true;
}
