_: {
  stylix.targets.rio.enable = false;

  programs.rio = {
    enable = true;

    settings = {
      performance = "High";
      hide-cursor-when-typing = true;
      confirm-before-quit = false;
      use-fork = true;

      fonts = {
        family = "MesloLGS Nerd Font";
        size = 14;
        features = ["calt" "clig" "liga"];

        regular = {
          family = "MesloLGS Nerd Font";
          style = "Normal";
          weight = 400;
        };
        bold = {
          family = "MesloLGS Nerd Font";
          style = "Normal";
          weight = 800;
        };
        italic = {
          family = "MesloLGS Nerd Font";
          style = "Italic";
          weight = 400;
        };
        bold-italic = {
          family = "MesloLGS Nerd Font";
          style = "Italic";
          weight = 800;
        };
      };

      window = {
        opacity = 0.4;
        blur = true;
        decorations = "Disabled";
        padding-x = 10;
        padding-y = [10 10];
      };

      renderer = {
        backend = "Automatic";
        performance = "High";
        disable-unfocused-render = true;
      };

      scrolling = {
        history = 50000;
        multiplier = 3;
      };

      cursor = {
        shape = "block";
        blinking = true;
        blinking-interval = 500;
      };

      keyboard = {
        use-kitty-keyboard-protocol = true;
      };

      navigation = {
        mode = "BottomTab";
        hide-if-single = true;
        clickable = true;
      };

      # catppuccin mocha
      colors = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        cursor = "#f5e0dc";
        tabs = "#181825";
        tabs-active = "#cba6f7";
        tabs-active-foreground = "#1e1e2e";
        bar = "#1e1e2e";

        black = "#45475a";
        red = "#f38ba8";
        green = "#a6e3a1";
        yellow = "#f9e2af";
        blue = "#89b4fa";
        magenta = "#f5c2e7";
        cyan = "#94e2d5";
        white = "#bac2de";

        light-black = "#585b70";
        light-red = "#f38ba8";
        light-green = "#a6e3a1";
        light-yellow = "#f9e2af";
        light-blue = "#89b4fa";
        light-magenta = "#f5c2e7";
        light-cyan = "#94e2d5";
        light-white = "#a6adc8";
      };

      bindings.keys = [
        {key = "ctrl+shift+t"; action = "CreateTab";}
        {key = "ctrl+shift+w"; action = "CloseTab";}
        {key = "ctrl+tab"; action = "SelectNextTab";}
        {key = "ctrl+shift+tab"; action = "SelectPrevTab";}
        {key = "alt+1"; action = "SelectTab1";}
        {key = "alt+2"; action = "SelectTab2";}
        {key = "alt+3"; action = "SelectTab3";}
        {key = "alt+4"; action = "SelectTab4";}
        {key = "alt+5"; action = "SelectTab5";}
        {key = "ctrl+equal"; action = "IncreaseFontSize";}
        {key = "ctrl+minus"; action = "DecreaseFontSize";}
        {key = "ctrl+0"; action = "ResetFontSize";}
      ];
    };
  };
}
