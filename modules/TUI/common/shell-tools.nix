{pkgs, ...}: {
  programs = {
    carapace = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = false; # conflicts with fzf-tab: double-escapes spaces in paths (Aloxaf/fzf-tab#503)
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      historyWidget.command = ""; # Ctrl-R owned by atuin
      defaultCommand = "${pkgs.fd}/bin/fd --type f --color=always";
      defaultOptions = [
        "--border"
        "--ansi"
        "--layout=reverse"
      ];
      colors = {
        "bg+" = "#434C5E";
        "fg+" = "#D8DEE9";
        "hl+" = "#A3BE8C";
        bg = "#2E3440";
        fg = "#D8DEE9";
        header = "#4C566A";
        hl = "#A3BE8C";
        info = "#4C566A";
        marker = "#EBCB8B";
        pointer = "#BF616A";
        prompt = "#81A1C1";
        spinner = "#4C566A";
      };
    };

    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
      settings.updates = {
        auto_update = true;
        auto_update_interval_hours = 100;
      };
    };

    yazi = {
      enable = true;
      shellWrapperName = "y";
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      options = ["--cmd cd"];
    };
  };
}
