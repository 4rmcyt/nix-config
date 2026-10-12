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
      include themes/noctalia.conf
      mouse_map right press ungrabbed paste_from_clipboard
      map media_pause no_op
      map media_play no_op
      map media_stop no_op
      map media_next no_op
      map media_previous no_op
    '';
    settings = {
      term = "xterm-kitty";
      confirm_os_window_close = 0;
      hide_window_decorations = "no";
      dynamic_background_opacity = true;
      enable_audio_bell = false;
      notify_on_cmd_finish = "unfocused 10";
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
      symbol_map = "${import ../nerd-symbol-ranges.nix} Symbols Nerd Font";
    };
  };

  # kitten ssh only works inside kitty; zellij may block its escape codes.
  programs.zsh.initContent = ''
    [[ -n $KITTY_WINDOW_ID ]] && alias s="kitten ssh"
  '';
}
