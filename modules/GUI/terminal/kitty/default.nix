{pkgs, ...}: {
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    shellIntegration.enableZshIntegration = true;
    font = {
      name = "MesloLGS Nerd Font";
      size = 14;
    };
    extraConfig = ''
      include dank-theme.conf
      include dank-tabs.conf
      map end scroll_end
      map home scroll_home
    '';
    settings = {
      term = "xterm-kitty";
      confirm_os_window_close = 0;
      dynamic_background_opacity = true;
      enable_audio_bell = false;
      tab_bar_style = "fade";
      tab_bar_edge = "bottom";
      active_tab_foreground = "#000";
      active_tab_background = "#73D216";
      active_tab_font_style = "italic";
      inactive_tab_foreground = "#444";
      inactive_tab_background = "#999";
      inactive_tab_font_style = "normal";
      cursor_trail = 200;
      cursor_trail_decay = "0.1 0.4";
      cursor_trail_start_threshold = 2;
      mouse_hide_wait = "-3.0";
      window_padding_width = 10;
      background_opacity = "0.4";
      background_blur = 5;
      scrollback_lines = 50000;
      scrollback_pager_history_size = 100;
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";
      symbol_map = let
        mappings = [
          "U+23FB-U+23FE"
          "U+2B58"
          "U+E200-U+E2A9"
          "U+E0A0-U+E0A3"
          "U+E0B0-U+E0BF"
          "U+E0C0-U+E0C8"
          "U+E0CC-U+E0CF"
          "U+E0D0-U+E0D2"
          "U+E0D4"
          "U+E700-U+E7C5"
          "U+F000-U+F2E0"
          "U+2665"
          "U+26A1"
          "U+F400-U+F4A8"
          "U+F67C"
          "U+E000-U+E00A"
          "U+F300-U+F313"
          "U+E5FA-U+E62B"
        ];
      in
        (builtins.concatStringsSep "," mappings) + " Symbols Nerd Font";
    };
  };
}
