_: {
  stylix.targets.alacritty.enable = false;

  programs.alacritty = {
    enable = true;

    settings = {
      font = {
        normal = {
          family = "MesloLGS Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "MesloLGS Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "MesloLGS Nerd Font";
          style = "Italic";
        };
        size = 14.0;
      };

      window = {
        padding = {
          x = 10;
          y = 10;
        };
        opacity = 0.4;
        blur = true;
        decorations = "None";
        dynamic_title = true;
      };

      scrolling = {
        history = 50000;
        multiplier = 3;
      };

      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
        unfocused_hollow = true;
      };

      mouse = {
        hide_when_typing = true;
        bindings = [
          {
            mouse = "Right";
            action = "Paste";
          }
        ];
      };

      keyboard.bindings = [
        {
          key = "C";
          mods = "Control|Shift";
          action = "Copy";
        }
        {
          key = "V";
          mods = "Control|Shift";
          action = "Paste";
        }
        {
          key = "Plus";
          mods = "Control";
          action = "IncreaseFontSize";
        }
        {
          key = "Minus";
          mods = "Control";
          action = "DecreaseFontSize";
        }
        {
          key = "Key0";
          mods = "Control";
          action = "ResetFontSize";
        }
        {
          key = "F11";
          action = "ToggleFullscreen";
        }
      ];

      bell.duration = 0;
    };
  };
}
