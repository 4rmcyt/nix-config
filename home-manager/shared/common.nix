{
  pkgs,
  lib,
  ...
}: {
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = ["--border" "--ansi" "--layout=reverse"];
      defaultCommand = "${pkgs.fd}/bin/fd --type f --color=always";
      colors = {
        fg = "#D8DEE9";
        bg = "#2E3440";
        hl = "#A3BE8C";
        "fg+" = "#D8DEE9";
        "bg+" = "#434C5E";
        "hl+" = "#A3BE8C";
        pointer = "#BF616A";
        info = "#4C566A";
        spinner = "#4C566A";
        header = "#4C566A";
        prompt = "#81A1C1";
        marker = "#EBCB8B";
      };
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "4rmcyt";
          email = "redacted@example.com";
          signingkey = "D85B52C9288A138E";
        };
        commit.gpgsign = true;
        gpg.program = "gpg";
      };
    };

    gpg = {
      enable = true;
      settings = {
        # Display options
        keyid-format = "long";
        with-keygrip = true;
        with-key-origin = true;
        with-fingerprint = true;
        with-subkey-fingerprint = true;

        # Security and verification
        require-cross-certification = true;
        no-symkey-cache = true;
        throw-keyids = true;

        # Algorithm preferences
        personal-cipher-preferences = "AES256 AES192 AES";
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

        # Certificate preferences
        cert-digest-algo = "SHA512";
        s2k-digest-algo = "SHA512";
        s2k-cipher-algo = "AES256";

        # Charset and display
        charset = "utf-8";
        fixed-list-mode = true;
        no-comments = true;
        no-emit-version = true;
        no-greeting = true;
        keyserver-options = "no-honor-keyserver-url";
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";

        # Use agent
        use-agent = true;
      };
    };

    helix = {
      enable = true;
      settings = {
        theme = "heisenberg";
        editor = {
          true-color = true;
          line-number = "relative";
          mouse = false;
          cursorline = true;
          bufferline = "multiple";
          default-line-ending = "lf";
          cursor-shape.insert = "bar";
          cursor-shape.select = "underline";
          lsp.display-inlay-hints = true;
          lsp.display-messages = true;
          file-picker.hidden = false;
          file-picker.git-ignore = true;
        };
      };
      languages.language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
        }
      ];
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      options = ["--cmd cd"];
    };

    yazi = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
      settings.updates = {
        auto_update = true;
        auto_update_interval_hours = 100;
      };
    };

    carapace = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };
  };

  services.ssh-agent.enable = true;
}
