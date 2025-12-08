{pkgs, ...}: {
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()
      -- Color scheme
      config.color_scheme = 'Dracula+'
      return config
    '';
  };
}
