_: {
  programs.rio = {
    enable = true;

    settings = {
      hide-mouse-cursor-when-typing = true;
      confirm-before-quit = false;
      use-fork = true;
      scrollback-history-limit = 50000;
      line-height = 1.15;
      padding = [10];

      fonts = {
        family = "MesloLGS Nerd Font";
        size = 14;
        features = ["calt" "clig" "liga"];

        regular = {
          family = "MesloLGS Nerd Font";
          style = "default";
        };
        bold = {
          family = "MesloLGS Nerd Font";
          style = "default";
        };
        italic = {
          family = "MesloLGS Nerd Font";
          style = "Italic";
        };
        bold-italic = {
          family = "MesloLGS Nerd Font";
          style = "Italic";
        };
      };

      window = {
        opacity = 0.4;
        blur = true;
        decorations = "Disabled";
      };

      renderer = {
        backend = "Vulkan";
        disable-unfocused-render = true;
      };

      scroll = {
        multiplier = 3.0;
        divider = 1.0;
      };

      cursor = {
        shape = "block";
        blinking = true;
        blinking-interval = 500;
      };

      navigation = {
        mode = "Tab";
        hide-if-single = true;
      };

      bindings.keys = [
        {
          key = "ctrl+shift+t";
          action = "CreateTab";
        }
        {
          key = "ctrl+shift+w";
          action = "CloseTab";
        }
        {
          key = "ctrl+tab";
          action = "SelectNextTab";
        }
        {
          key = "ctrl+shift+tab";
          action = "SelectPrevTab";
        }
        {
          key = "alt+1";
          action = "SelectTab1";
        }
        {
          key = "alt+2";
          action = "SelectTab2";
        }
        {
          key = "alt+3";
          action = "SelectTab3";
        }
        {
          key = "alt+4";
          action = "SelectTab4";
        }
        {
          key = "alt+5";
          action = "SelectTab5";
        }
        {
          key = "ctrl+equal";
          action = "IncreaseFontSize";
        }
        {
          key = "ctrl+minus";
          action = "DecreaseFontSize";
        }
        {
          key = "ctrl+0";
          action = "ResetFontSize";
        }
      ];
    };
  };
}
