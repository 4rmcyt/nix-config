_: {
  programs.rio = {
    enable = true;

    # Static copy of noctalia's kitty palette (~/.config/kitty/themes/noctalia.conf); noctalia has no rio template.
    themes.noctalia.colors = {
      background = "#1d2021";
      foreground = "#d4be98";
      cursor = "#d4be98";
      selection-background = "#282828";
      selection-foreground = "#d4be98";
      tabs = "#d4be98";
      tabs-active = "#a9b665";
      bar = "#282828";

      black = "#7c6f64";
      red = "#ea6962";
      green = "#a9b665";
      yellow = "#d8a657";
      blue = "#7daea3";
      magenta = "#d3869b";
      cyan = "#89b482";
      white = "#d4be98";

      light-black = "#928374";
      light-red = "#ea6962";
      light-green = "#a9b665";
      light-yellow = "#d8a657";
      light-blue = "#7daea3";
      light-magenta = "#d3869b";
      light-cyan = "#89b482";
      light-white = "#ddc7a1";
    };

    settings = {
      theme = "noctalia";
      confirm-before-quit = false;
      hide-mouse-cursor-when-typing = true;
      line-height = 1.15;
      padding = [10];
      scrollback-history-limit = 50000;
      use-fork = true;

      fonts = {
        family = "MesloLGS Nerd Font";
        size = 14;
        features = ["calt" "clig" "liga"];
      };

      window = {
        opacity = 0.92;
        decorations = "Disabled";
      };

      renderer = {
        backend = "Vulkan";
        disable-unfocused-render = true;
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

      # ctrl+shift+t/w, ctrl+tab, ctrl+±/0 are Linux defaults; only alt+N is custom.
      bindings.keys = map (n: {
        key = toString n;
        "with" = "alt";
        action = "SelectTab(${toString (n - 1)})";
      }) [1 2 3 4 5];
    };
  };
}
