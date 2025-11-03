_: {
  programs.konsole = {
    enable = true;
    customColorSchemes = {
      "Catppuccin${theme.Flavor}" = ./catppuccin-${theme.flavor}.colorscheme;
    };
    defaultProfile = "Default";
    profiles.default = {
      name = "Default";
      colorScheme = "Dracula";
      font = {
        name = "MesloLGS NF";
        size = 14;
      };
    };
  };

  # Make Konsole the default terminal app
  programs.plasma.configFile = {
    "kdeglobals"."General"."TerminalService" = "org.kde.konsole.desktop";
  };
}
