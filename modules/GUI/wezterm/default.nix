{ pkgs, ... }:
{
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()
      -- Color scheme
      config.color_scheme = 'Dracula+'
      config.window_close_confirmation = 'NeverPrompt'
      config.skip_close_confirmation_for_processes_named = {
        'bash',
        'sh',
        'zsh',
        'fish',
        'tmux',
        'nu',
        'zellij',
      }
      return config
    '';
  };
}
