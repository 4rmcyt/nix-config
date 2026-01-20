_: {
  programs.zed-editor.userSettings = {
    # ===== Appearance =====
    theme = {
      mode = "dark";
      light = "Bearded Theme Arc";
      dark = "Bearded Theme Arc";
    };
    icon_theme = "Material Icon Theme";
    buffer_font_family = "Maple Mono NF";
    buffer_font_size = 16.0;
    buffer_font_features = {
      calt = true;
      liga = true;
    };
    ui_font_family = "Maple Mono NF";
    ui_font_size = 15.0;
    colorize_brackets = true;

    # ===== Editor =====
    autosave.after_delay.milliseconds = 1000;
    base_keymap = "VSCode";
    ensure_final_newline_on_save = true;
    format_on_save = "on";
    indent_guides = {
      active_line_width = 2;
      line_width = 1;
    };
    minimap.show = "auto";
    remove_trailing_whitespace_on_save = true;
    tab_size = 2;
    tabs = {
      file_icons = true;
      git_status = true;
      show_diagnostics = "all";
    };
    telemetry = {
      diagnostics = false;
      metrics = false;
    };

    # ===== Terminal =====
    terminal = {
      font_family = "MesloLGS NF";
      font_size = 16.0;
      shell.program = "zsh";
      working_directory = "current_project_directory";
    };
  };
}
