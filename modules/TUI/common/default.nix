{
  pkgs,
  lib,
  ...
}: {
  programs = {
    carapace = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = false; # conflicts with fzf-tab: double-escapes spaces in paths (Aloxaf/fzf-tab#503)
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
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
      defaultCommand = "${pkgs.fd}/bin/fd --type f --color=always";
      defaultOptions = [
        "--border"
        "--ansi"
        "--layout=reverse"
      ];
      enable = true;
      enableZshIntegration = true;
    };

    git = {
      enable = true;
      settings = {
        commit.gpgsign = true;
        gpg.program = "gpg";
        user = {
          email = "redacted@example.com";
          name = "4rmcyt";
          signingkey = "D85B52C9288A138E";
        };
      };
    };

    gpg = {
      enable = true;
      settings = {
        # Algorithm preferences
        cert-digest-algo = "SHA512";
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        personal-cipher-preferences = "AES256 AES192 AES";
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        s2k-cipher-algo = "AES256";
        s2k-digest-algo = "SHA512";

        # Charset and display
        charset = "utf-8";
        fixed-list-mode = true;
        keyid-format = "long";
        keyserver-options = "no-honor-keyserver-url";
        list-options = "show-uid-validity";
        no-comments = true;
        no-emit-version = true;
        no-greeting = true;
        verify-options = "show-uid-validity";
        with-fingerprint = true;
        with-key-origin = true;
        with-keygrip = true;
        with-subkey-fingerprint = true;

        # Security and verification
        no-symkey-cache = true;
        require-cross-certification = true;
        throw-keyids = true;
        use-agent = true;
      };
    };

    helix = {
      enable = true;
      languages.language = [
        {
          auto-format = true;
          formatter.command = lib.getExe pkgs.nixfmt;
          name = "nix";
          language-servers = ["nil" "claude-code"];
        }
      ];
      languages.language-server.nil = {
        config = {
          nix.flake.autoArchive = true;
        };
      };
      languages.language-server.claude-code = {
        command = "claude-code";
        args = ["lsp"];
      };
      settings = {
        editor = {
          bufferline = "multiple";
          cursor-shape.insert = "bar";
          cursor-shape.select = "underline";
          cursorline = true;
          default-line-ending = "lf";
          file-picker.git-ignore = true;
          file-picker.hidden = false;
          line-number = "relative";
          lsp.display-inlay-hints = true;
          lsp.display-messages = true;
          mouse = false;
          true-color = true;
        };
        theme = "heisenberg";
      };
    };

    rclone.enable = false;

    # SSH config managed at system level to avoid symlink permission issues
    ssh.enable = false;

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

  # SSH handled by gpg-agent with enableSSHSupport
  services.ssh-agent.enable = false;
}
