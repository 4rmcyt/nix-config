{pkgs, ...}: {
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
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # xdg-desktop-portal-gtk reads theme/font from GSettings/dconf, not settings.ini;
  # without a GNOME session nothing else populates this path, breaking dialog text layout.
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = "catppuccin-mocha-blue-standard";
    icon-theme = "Papirus-Dark";
    font-name = "Maple Mono 12";
    document-font-name = "Maple Mono 12";
    monospace-font-name = "Maple Mono 12";
    # libadwaita/GTK4 apps (Nemo's GTK4 build, file choosers, etc.) pick
    # dark/light from this key rather than the theme name.
    color-scheme = "prefer-dark";
  };

  # QT_STYLE_OVERRIDE=kvantum is a no-op without an actual theme selected — otherwise
  # falls back to unstyled default (plain light Qt/Fusion palette).
  xdg.dataFile."Kvantum/catppuccin-mocha-blue".source = "${pkgs.catppuccin-kvantum.override {
    variant = "mocha";
    accent = "blue";
  }}/share/Kvantum/catppuccin-mocha-blue";

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-blue
  '';

  # Gives QWidgets apps a dark QPalette and routes native dialogs through KDE's own
  # implementation. Does NOT fix Kirigami/QQC2 apps (kdeconnect-app) — confirmed dead
  # end, those never consult QWidgets palette/dialog machinery.
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

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
