{pkgs, ...}: {
  # ============================================
  # FONTS
  # ============================================
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    fantasque-sans-mono
    maple-mono.NF
    nerd-fonts.caskaydia-cove
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
    twemoji-color-font
  ];

  # ============================================
  # GTK THEMING
  # ============================================

  # Force overwrite GTK config files to avoid conflicts
  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/gtk.css".force = true;

  gtk = {
    enable = true;

    font = {
      name = "Maple Mono";
      size = 12;
    };

    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = ["blue"];
      };
    };

    gtk4.theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = ["blue"];
      };
    };

    iconTheme = {
      name = "Tela-dark";
      package = pkgs.tela-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # xdg-desktop-portal-gtk (file chooser, etc.) reads theme/font via
  # GSettings/dconf under org/gnome/desktop/interface, not the settings.ini
  # files above — those only cover regular GTK apps. Without a GNOME
  # session nothing ever populates this dconf path, so the portal falls
  # back with no font set and renders dialogs with broken/collapsed text
  # layout. Mirrors the values set in the `gtk` block above.
  # https://wiki.hypr.land/Nix/Hyprland-on-NixOS/#fixing-problems-with-themes
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = "catppuccin-mocha-blue-standard";
    icon-theme = "Tela-dark";
    font-name = "Maple Mono 12";
    document-font-name = "Maple Mono 12";
    monospace-font-name = "Maple Mono 12";
    # libadwaita/GTK4 apps (Nemo's GTK4 build, file choosers, etc.) pick
    # dark/light from this key rather than the theme name.
    color-scheme = "prefer-dark";
  };

  # ============================================
  # QT/KVANTUM THEMING
  # ============================================
  # QT_STYLE_OVERRIDE=kvantum (set in hyprland/niri sessionVariables) is a
  # no-op without an actual Kvantum theme selected — Kvantum falls back to
  # its unstyled default, which reads as a plain light Qt/Fusion palette.
  # This affects Kirigami/QQC2 apps (kdeconnect-app) same as QWidgets apps.
  xdg.dataFile."Kvantum/catppuccin-mocha-blue".source = "${pkgs.catppuccin-kvantum.override {
    variant = "mocha";
    accent = "blue";
  }}/share/Kvantum/catppuccin-mocha-blue";

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-blue
  '';

  # Gives QWidgets apps (Ark, kcmshell/systemsettings modules, etc.) a full
  # dark QPalette instead of Kvantum's default light Fusion fallback, and
  # routes their native dialogs (file open/save, print, color picker)
  # through KDE's own implementation instead of Qt's — otherwise those
  # dialogs stay light even when the app around them is dark. Both keys
  # confirmed present in libqt5ct.so/libqt6ct.so via strings.
  #
  # Does NOT fix Kirigami/QQC2 apps (kdeconnect-app) — those never consult
  # QWidgets palette/dialog machinery at all; confirmed dead end after
  # extensive live testing (org.kde.desktop QQC2 style + plasma-integration
  # + correct kdeglobals still rendered light).
  qt.qt5ctSettings.Appearance = {
    custom_palette = true;
    color_scheme_path = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
    standard_dialogs = "kde";
  };
  qt.qt6ctSettings.Appearance = {
    custom_palette = true;
    color_scheme_path = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
    standard_dialogs = "kde";
  };

  # ============================================
  # CURSOR CONFIGURATION
  # ============================================
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
