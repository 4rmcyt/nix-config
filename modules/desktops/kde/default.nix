{pkgs, ...}: {
  imports = [
    ../../GUI/flatpak/kde
  ];

  environment.sessionVariables = {
    # Wayland Support
    NIXOS_OZONE_WL = "1";
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";

    # Browser Optimization
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  environment.systemPackages = with pkgs; [
    # KDE Applications
    kdePackages.ark
    kdePackages.discover
    kdePackages.filelight
    kdePackages.gwenview
    kdePackages.kcalc
    kdePackages.kcharselect
    kdePackages.kclock
    kdePackages.kfind
    kdePackages.kgpg
    kdePackages.kio-extras
    kdePackages.konsole
    kdePackages.ksystemlog
    kdePackages.kate
    kdePackages.okular
    kdePackages.partitionmanager
    kdePackages.plasma-browser-integration
    kdePackages.qtmultimedia
    kdePackages.qtsvg
    kdePackages.sddm-kcm
    kdePackages.signon-kwallet-extension
    kdePackages.spectacle
    kdePackages.systemsettings
    kwalletcli
    kdePackages.qtwayland
    libsForQt5.qt5.qtwayland
    kdePackages.dolphin
    tail-tray

    # SDDM Themes
    sddm-astronaut
    sddm-sugar-dark

    # KDE Portal Support
    libdbusmenu

    # KDE Themes and Icons
    gruvbox-dark-icons-gtk
    gruvbox-material-gtk-theme
    gruvbox-plus-icons
    kde-gruvbox
    plasma-panel-colorizer
    crystal-dock

    # Qt/KDE Support Packages
    pinentry-qt
    ibus
    ibus-with-plugins
  ];

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

  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };
}
