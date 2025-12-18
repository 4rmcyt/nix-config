{ pkgs, ... }:
{
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;

    # extraConfig = ''
    #   local wezterm = require 'wezterm'
    #   local config = wezterm.config_builder()
    #   -- Color scheme
    #   config.color_scheme = 'Dracula+'
    #   config.window_close_confirmation = 'NeverPrompt'
    #   config.skip_close_confirmation_for_processes_named = {
    #     'bash',
    #     'sh',
    #     'zsh',
    #     'fish',
    #     'tmux',
    #     'nu',
    #     'zellij',
    #   }
    #   return config
    # '';
    extraConfig = ''
      local wez = require('wezterm')
      return {
        default_prog     = { 'zsh' },
        cell_width = 0.85,
        -- Performance
        --------------
        front_end        = "WebGpu",
        enable_wayland   = true,
        scrollback_lines = 1024,
        -- Fonts
        --------
        font         = wez.font_with_fallback({
          "Iosevka Nerd Font",
          "Material Design Icons",
        }),
        initial_rows = 18,
        initial_cols = 85,
        dpi = 96.0,
        bold_brightens_ansi_colors = true,
        font_rules    = {
          {
            italic = true,
            font   = wez.font("Iosevka Nerd Font", { italic = true })
          }
        },
        --font_antialias = "Subpixel",
        --font_hinting = "VerticalSubpixel",
        font_size         = 14.0,
        line_height       = 1.15,
        harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' },
        -- Bling
        --------
        color_scheme = 'Dracula+',
        default_cursor_style = "SteadyUnderline",
        -- Tabbar
        ---------
        enable_tab_bar               = true,
        use_fancy_tab_bar            = true,
        hide_tab_bar_if_only_one_tab = true,
        show_tab_index_in_tab_bar    = false,
        -- Miscelaneous
        ---------------
        window_close_confirmation = 'NeverPrompt',
        skip_close_confirmation_for_processes_named = {
          'bash',
          'sh',
          'zsh',
          'fish',
          'tmux',
          'nu',
          'zellij',
        }
        inactive_pane_hsb         = {
          saturation = 1.0, brightness = 0.8
        },
        check_for_updates = false,
        window_background_opacity = 1
      }
    '';
  };
}
