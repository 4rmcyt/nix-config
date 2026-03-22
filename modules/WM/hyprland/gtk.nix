{pkgs, ...}: {
  # ============================================
  # FONTS
  # ============================================
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Nerd Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    nerd-fonts.symbols-only

    # Emoji Fonts
    twemoji-color-font
    noto-fonts-color-emoji

    # Additional Fonts
    fantasque-sans-mono
    maple-mono.NF
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

    gtk3.extraConfig.gtk-decoration-layout = "appmenu:minimize,maximize,close";
    gtk4.extraConfig.gtk-decoration-layout = "appmenu:minimize,maximize,close";

    font = {
      name = "Maple Mono";
      size = 12;
    };

    theme = {
      name = "Kanagawa-B";
      package = pkgs.kanagawa-gtk-theme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme.override {color = "green";};
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # ============================================
  # CURSOR CONFIGURATION
  # ============================================
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };
}
