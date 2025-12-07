{pkgs, ...}: {
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local tabline = wezterm.plugin.require('https://github.com/michaelbrusegard/tabline.wez')

      local config = wezterm.config_builder()

      -- Color scheme
      config.color_scheme = 'Dracula+'

      -- Tabline configuration
      tabline.setup({
        options = {
          theme = 'Dracula+',
        },
      })
      tabline.apply_to_config(config)

      return config
    '';
  };
}
