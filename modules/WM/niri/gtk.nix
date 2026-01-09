{pkgs, ...}: {
  # ============================================
  # GTK THEMING - DMS Integration
  # ============================================

  home.packages = with pkgs; [
    # GTK Theme Requirements
    adw-gtk3-theme # Adwaita-based GTK3/4 theme
    gsettings-desktop-schemas

    # Icon Themes (Popular DMS-compatible options)
    papirus-icon-theme # Recommended: Excellent coverage
    # tela-icon-theme # Alternative: Modern design
    # adwaita-icon-theme # Fallback: GNOME default
  ];

  gtk = {
    enable = true;

    # Theme Configuration
    theme = {
      name = "adw-gtk3-dark"; # Base theme for GTK3/4
      package = pkgs.adw-gtk3-theme;
    };

    # Icon Theme
    iconTheme = {
      name = "Papirus-Dark"; # DMS-recommended icon theme
      package = pkgs.papirus-icon-theme;
    };

    # Font Configuration
    font = {
      name = "Inter";
      size = 11;
    };

    # GTK3 Settings
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = "menu:close";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = false;
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-menu-images = true;
      gtk-button-images = true;
    };

    # GTK4 Settings
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = "menu:close";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = false;
    };
  };

  # ============================================
  # GTK3/4 Custom CSS - DMS Dynamic Colors
  # ============================================

  # Import DMS-generated colors (when matugen is enabled)
  home.file.".config/gtk-3.0/gtk.css".text = ''
    /* DMS Dynamic Theming Integration */
    @import url("dank-colors.css");

    /* Additional custom styling can go here */
  '';

  home.file.".config/gtk-4.0/gtk.css".text = ''
    /* DMS Dynamic Theming Integration */
    @import url("dank-colors.css");

    /* Additional custom styling can go here */
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      font-name = "Inter 11";
      document-font-name = "Inter 11";
      monospace-font-name = "JetBrainsMono Nerd Font 10";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "menu:close";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };
}
