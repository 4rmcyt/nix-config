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
    maple-mono-custom
  ];

  # ============================================
  # GTK THEMING
  # ============================================
  gtk = {
    enable = true;

    font = {
      name = "Maple Mono";
      size = 12;
    };

    theme = {
      name = "Colloid-Green-Dark-Gruvbox";
      package = pkgs.colloid-gtk-theme.override {
        colorVariants = ["dark"];
        themeVariants = ["green"];
        tweaks = [
          "gruvbox"
          "rimless"
          "float"
        ];
      };
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
