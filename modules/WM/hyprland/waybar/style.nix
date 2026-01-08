_: let
  custom = {
    font = "Maple Mono NF";
    font_size = "14px";
    font_weight = "600";
    text_color = "#FBF1C7";
    background_0 = "#1D2021";
    background_1 = "#282828";
    background_2 = "#3C3836";
    border_color = "#928374";
    red = "#CC241D";
    green = "#98971A";
    yellow = "#FABD2F";
    blue = "#458588";
    magenta = "#B16286";
    cyan = "#689D6A";
    orange = "#D65D0E";
    orange_bright = "#FE8019";
    opacity = "1";
  };
in {
  programs.waybar.style = with custom; ''
    * {
      border: none;
      border-radius: 8px;
      padding: 0;
      margin: 0;
      font-family: ${font};
      font-weight: ${font_weight};
      font-size: ${font_size};
      min-height: 0;
    }

    window#waybar {
      background: transparent;
      color: ${text_color};
    }

    tooltip {
      background: ${background_1};
      border: 2px solid ${border_color};
      border-radius: 8px;
    }
    tooltip label {
      padding: 5px;
      color: ${text_color};
    }

    /* Launcher */
    #custom-launcher {
      background: transparent;
      color: ${text_color};
      font-size: 24px;
      padding: 0 12px;
      margin: 5px 0;
    }

    /* Workspaces */
    #workspaces {
      background: ${background_2};
      padding: 0 8px;
      margin: 5px 8px;
    }
    #workspaces button {
      color: ${text_color};
      padding: 0 8px;
      margin: 0 2px;
      background: transparent;
      transition: all 0.3s ease;
    }
    #workspaces button:hover {
      background: ${background_1};
      color: ${yellow};
    }
    #workspaces button.empty {
      color: ${border_color};
    }
    #workspaces button.active {
      background: ${orange};
      color: ${background_0};
      font-weight: bold;
    }

    /* Quicklinks */
    #custom-quicklinks-browser,
    #custom-quicklinks-code,
    #custom-quicklinks-files,
    #custom-quicklinks-telegram,
    #custom-quicklinks-terminal,
    #custom-quicklinks-jellyfin {
      background: transparent;
      padding: 0 10px;
      margin: 5px 4px;
      font-size: 24px;
      transition: all 0.3s ease;
    }
    #custom-quicklinks-browser { color: ${blue}; }
    #custom-quicklinks-code { color: ${cyan}; }
    #custom-quicklinks-files { color: ${yellow}; }
    #custom-quicklinks-telegram { color: ${cyan}; }
    #custom-quicklinks-terminal { color: ${green}; }
    #custom-quicklinks-jellyfin { color: ${magenta}; }

    #custom-quicklinks-browser:hover,
    #custom-quicklinks-code:hover,
    #custom-quicklinks-files:hover,
    #custom-quicklinks-telegram:hover,
    #custom-quicklinks-terminal:hover,
    #custom-quicklinks-jellyfin:hover {
      background: rgba(40, 40, 40, 0.3);
    }

    /* Window title */
    #window {
      background: ${background_2};
      padding: 0 12px;
      margin: 5px 8px;
      color: ${text_color};
    }

    /* Clock */
    #clock {
      color: ${text_color};
      background: transparent;
      padding: 0 10px;
      margin: 5px 4px;
      font-weight: bold;
      font-size: 24px;
      transition: all 0.3s ease;
    }

    /* System tray */
    #tray {
      background: ${background_2};
      padding: 0 8px;
      margin: 5px 8px;
    }
    #tray > .passive {
      -gtk-icon-effect: dim;
    }
    #tray > .needs-attention {
      -gtk-icon-effect: highlight;
      color: ${red};
    }
    #tray menu {
      background: ${background_1};
      border: 2px solid ${border_color};
      padding: 8px;
    }

    /* System info modules */
    #cpu,
    #memory,
    #disk,
    #pulseaudio,
    #network,
    #battery,
    #language {
      background: transparent;
      padding: 0 10px;
      margin: 5px 4px;
      font-size: 18px;
      transition: all 0.3s ease;
    }

    #cpu { }
    #memory { }
    #disk { }

    #pulseaudio {
      margin-left: 8px;
    }

    #battery.charging {
      color: ${green};
    }
    #battery.warning:not(.charging) {
      color: ${yellow};
    }
    #battery.critical:not(.charging) {
      color: ${red};
      animation: blink 0.5s linear infinite alternate;
    }

    /* Notification center */
    #custom-notification {
      background: ${background_2};
      padding: 0 10px;
      margin: 5px 4px;
    }

    /* Power menu */
    #custom-power-menu {
      background: ${red};
      color: ${background_0};
      padding: 0 12px;
      margin: 5px 8px 5px 4px;
      font-weight: bold;
    }

    @keyframes blink {
      to {
        color: ${background_1};
      }
    }
  '';
}
