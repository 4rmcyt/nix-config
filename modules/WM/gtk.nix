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
      name = "Kanagawa-B";
      package = pkgs.kanagawa-gtk-theme;
    };

    gtk4.theme = {
      name = "Kanagawa-B";
      package = pkgs.kanagawa-gtk-theme;
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
    gtk-theme = "Kanagawa-B";
    icon-theme = "Tela-dark";
    font-name = "Maple Mono 12";
    document-font-name = "Maple Mono 12";
    monospace-font-name = "Maple Mono 12";
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
