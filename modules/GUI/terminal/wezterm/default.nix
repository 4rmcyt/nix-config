{ pkgs, ... }: {
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()
      local act = wezterm.action

      -- Performance
      config.front_end = "WebGpu"
      config.enable_wayland = true
      config.scrollback_lines = 50000

      -- Fonts
      config.font = wezterm.font_with_fallback({
        "MesloLGS Nerd Font",
        "Symbols Nerd Font",
      })
      config.font_size = 14.0
      config.line_height = 1.15
      config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
      config.bold_brightens_ansi_colors = true

      -- Colors (catppuccin mocha)
      config.color_scheme = 'tokyonight'

      -- Window
      config.window_background_opacity = 0.8
      config.window_decorations = "NONE"
      config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }

      -- Cursor
      config.default_cursor_style = "BlinkingBlock"

      -- Tabs
      config.enable_tab_bar = true
      config.use_fancy_tab_bar = false
      config.hide_tab_bar_if_only_one_tab = true
      config.show_tab_index_in_tab_bar = false
      config.show_new_tab_button_in_tab_bar = false
      config.tab_bar_at_bottom = true
      show_close_tab_button_in_tabs = true

      -- Misc
      config.window_close_confirmation = 'NeverPrompt'
      config.audible_bell = "Disabled"

      config.inactive_pane_hsb = {
        saturation = 1.0,
        brightness = 0.8,
      }

      -- Keys
      config.keys = {
        { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
        { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
        { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
        { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = false } },
        { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
        { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
        { key = '1', mods = 'ALT', action = act.ActivateTab(0) },
        { key = '2', mods = 'ALT', action = act.ActivateTab(1) },
        { key = '3', mods = 'ALT', action = act.ActivateTab(2) },
        { key = '4', mods = 'ALT', action = act.ActivateTab(3) },
        { key = '5', mods = 'ALT', action = act.ActivateTab(4) },
        { key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
        { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
        { key = '0', mods = 'CTRL', action = act.ResetFontSize },
        { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },
      }

      -- Mouse
      config.mouse_bindings = {
        {
          event = { Down = { streak = 1, button = { WheelUp = 1 } } },
          mods = 'CTRL',
          action = act.IncreaseFontSize,
        },
        {
          event = { Down = { streak = 1, button = { WheelDown = 1 } } },
          mods = 'CTRL',
          action = act.DecreaseFontSize,
        },
        {
          event = { Down = { streak = 1, button = 'Right' } },
          mods = 'NONE',
          action = act.PasteFrom 'Clipboard',
        },
        {
          event = { Up = { streak = 1, button = 'Left' } },
          mods = 'NONE',
          action = act.CompleteSelection 'ClipboardAndPrimarySelection',
        },
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
