_: {
  programs.zed-editor.userSettings = {
    # ===== Languages =====
    languages = {
      Markdown.format_on_save = "on";

      Nix = {
        formatter.external = {
          command = "nixfmt";
          arguments = [
            "--quiet"
            "--"
          ];
        };
        language_servers = [
          "nixd"
          "!nil"
        ];
      };

      Python = {
        format_on_save = "on";
        formatter.external = {
          command = "black";
          arguments = [
            "-q"
            "-"
          ];
        };
        language_servers = [
          "pylsp"
          "ruff"
        ];
      };
    };
  };
}
