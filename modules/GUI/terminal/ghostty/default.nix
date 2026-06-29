_: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      background = "#19120c";
      background-opacity = 0.92;
      background-blur-radius = 25;
      clipboard-read = "allow";
      clipboard-trim-trailing-spaces = true;
      clipboard-write = "allow";
      config-file = "~/.config/ghostty/config-dankcolors";
      confirm-close-surface = false;
      copy-on-select = "clipboard";
      cursor-style = "block";
      cursor-style-blink = true;
      font-family = "JetBrainsMono Nerd Font";
      font-feature = ["+liga"];
      font-size = 13;
      gtk-single-instance = false;
      gtk-titlebar = false;
      keybind = [
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+w=close_surface"
        "ctrl+shift+n=new_window"
        "ctrl+plus=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+equal=reset_font_size"
        "ctrl+tab=next_tab"
        "ctrl+shift+tab=previous_tab"
        "alt+1=goto_tab:1"
        "alt+2=goto_tab:2"
        "alt+3=goto_tab:3"
        "alt+4=goto_tab:4"
        "alt+5=goto_tab:5"
        "f11=toggle_fullscreen"
      ];
      link-url = true;
      minimum-contrast = 1.15;
      mouse-hide-while-typing = true;
      quit-after-last-window-closed = false;
      scrollback-limit = 10000;
      shell-integration = "zsh";
      shell-integration-features = "sudo,cursor,no-title";
      unfocused-split-opacity = 0.85;
      window-decoration = false;
      window-padding-balance = true;
      window-padding-x = 8;
      window-padding-y = 8;
      window-save-state = "always";
      window-show-tab-bar = "auto";
      window-theme = "dark";
    };
  };
}
