{
  pkgs,
  lib,
  ...
}: {
  programs.helix = {
    enable = true;

    extraPackages = with pkgs; [
      alejandra
      pyright
      lua-language-server
      bash-language-server
      shfmt
      ruff
      stylua
    ];

    languages.language-server = {
      nil = {
        command = lib.getExe pkgs.nil;
        config.nix.flake.autoArchive = true;
      };
      claude-code = {
        command = "claude-code";
        args = ["lsp"];
      };
      pyright = {
        command = "pyright-langserver";
        args = ["--stdio"];
      };
      lua-language-server.command = "${pkgs.lua-language-server}/bin/lua-language-server";
      bash-language-server = {
        command = "${pkgs.bash-language-server}/bin/bash-language-server";
        args = ["start"];
      };
    };

    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.alejandra;
        language-servers = ["nil" "claude-code"];
      }
      {
        name = "python";
        auto-format = true;
        formatter = {
          command = "${pkgs.ruff}/bin/ruff";
          args = ["format" "--stdin-filename" "%{buffer_name}" "-"];
        };
        language-servers = ["pyright" "claude-code"];
      }
      {
        name = "lua";
        auto-format = true;
        formatter = {
          command = "${pkgs.stylua}/bin/stylua";
          args = ["-"];
        };
        language-servers = ["lua-language-server" "claude-code"];
      }
      {
        name = "bash";
        auto-format = true;
        formatter = {
          command = "${pkgs.shfmt}/bin/shfmt";
          args = ["-"];
        };
        language-servers = ["bash-language-server" "claude-code"];
      }
    ];

    settings = {
      theme = "kanagawa";
      editor = {
        bufferline = "multiple";
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
        cursorline = true;
        default-line-ending = "lf";
        file-picker = {
          git-ignore = true;
          hidden = false;
        };
        line-number = "relative";
        lsp = {
          display-inlay-hints = true;
          display-messages = true;
        };
        mouse = true;
        true-color = true;
        rulers = [80 120];
        auto-pairs = true;
        indent-guides = {
          render = true;
          character = "│";
        };
        statusline = {
          left = ["mode" "spinner" "file-name" "read-only-indicator" "file-modification-indicator"];
          center = [];
          right = ["diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type"];
          separator = "│";
        };
      };
    };
  };
}
