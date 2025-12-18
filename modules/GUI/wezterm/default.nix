{ pkgs, ... }:
{
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;
    extraConfig = ''
            local wezterm = require 'wezterm'
            local config = wezterm.config_builder()
            local act = wezterm.action

            config.default_prog = {'zsh'}
            config.cell_width = 0.85

            -- Performance
            --------------
            config.front_end = "OpenGL"
            config.enable_wayland = true
            config.scrollback_lines = 3500

            -- Fonts
            --------
            config.font = wezterm.font_with_fallback({
               "MesloLGS Nerd Font",
               "Symbols Nerd Font",
               "Material Design Icons",
            })
            config.initial_rows = 24
            config.initial_cols = 85
            config.bold_brightens_ansi_colors = true
            config.font_rules = {
              {
                font = wezterm.font("MesloLGS Nerd Font", { italic = false })
              }
            }
            --config.font_antialias = "Subpixel"
            --config.font_hinting = "VerticalSubpixel"
            config.font_size = 14.0
            config.line_height = 1.15
            config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

            -- Bling
            --------
            config.color_scheme = 'Dracula (Official)'
            config.default_cursor_style = "BlinkingBlock"

            -- Tabbar
            --------
            config.enable_tab_bar = true
            config.use_fancy_tab_bar = true
            config.hide_tab_bar_if_only_one_tab = false
            config.show_tab_index_in_tab_bar = false
            config.show_new_tab_button_in_tab_bar = true

            -- Miscellaneous
            ---------------
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

            config.inactive_pane_hsb = {
              saturation = 1.0, brightness = 0.8
            }
            config.check_for_updates = false
            config.window_background_opacity = 0.4
            config.kde_window_background_blur = true

            config.mouse_bindings = {
              -- Scrolling up while holding CTRL increases the font size
              {
                event = { Down = { streak = 1, button = { WheelUp = 1 } } },
                mods = 'CTRL',
                action = act.IncreaseFontSize,
              },

              -- Scrolling down while holding CTRL decreases the font size
              {
                event = { Down = { streak = 1, button = { WheelDown = 1 } } },
                mods = 'CTRL',
                action = act.DecreaseFontSize,
              },

               -- Right click sends "woot" to the terminal
              {
                event = { Down = { streak = 1, button = 'Right' } },
                mods = 'NONE',
                action = act.SendString 'woot',
              },

              -- Change the default click behavior so that it only selects
              -- text and doesn't open hyperlinks
              {
                event = { Up = { streak = 1, button = 'Left' } },
                mods = 'NONE',
                action = act.CompleteSelection 'ClipboardAndPrimarySelection',
              },

              -- and make CTRL-Click open hyperlinks
              {
                event = { Up = { streak = 1, button = 'Left' } },
                mods = 'CTRL',
                action = act.OpenLinkAtMouseCursor,
              },
            }

            return config
    '';
  };
}
