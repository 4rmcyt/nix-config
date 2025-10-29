{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/GUI/firefox
    ../shared/common.nix
    ../shared/zsh.nix
    ../shared/tmux.nix
  ];

  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";
    stateVersion = "25.05";

    packages = with pkgs; [
      # Development tools
      bat
      davfs2
      ffmpeg
      python3
      vscode-fhs

      # GUI applications
      obsidian
      signal-desktop

      # Laptop utilities
      brightnessctl
      acpi
      powertop

      # GNOME applications
      gnome-tweaks
      gnome-extension-manager

      # Themes and icons
      adwaita-icon-theme
      gnome-themes-extra
    ];

    sessionVariables = {
      # Graphics & Display (AMD)
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "radeonsi";

      # Wayland Support
      GDK_BACKEND = "wayland,x11";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";

      EDITOR = lib.mkForce "hx";
      BROWSER = lib.mkForce "firefox";
    };
  };

  # GTK theme configuration
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # GNOME dconf settings
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/power" = {
      sleep-inactive-ac-timeout = 1800;
      sleep-inactive-battery-timeout = 900;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "suspend";
      sleep-inactive-ac-type = "suspend";
      sleep-inactive-battery-type = "suspend";
    };
  };

  programs = {
    browserpass.enable = true;

    # Terminal
    gnome-terminal = {
      enable = true;
      profile = {
        default = {
          default = true;
          visibleName = "Default";
          font = "MesloLGS NF 11";
          showScrollbar = false;
          colors = {
            backgroundColor = "#282828";
            foregroundColor = "#ebdbb2";
            cursor = {
              background = "#ebdbb2";
              foreground = "#282828";
            };
          };
        };
      };
    };

    # Git configuration
    git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your.email@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
      };
    };
  };

  programs.zsh.sessionVariables = lib.mkMerge [
    {
      EDITOR = "hx";
    }
  ];

  services = {
    gpg-agent.enable = true;

    # GNOME services are managed by the desktop environment
  };
}
