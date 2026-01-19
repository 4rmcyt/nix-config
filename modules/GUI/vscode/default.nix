{
  pkgs,
  lib,
  ...
}: {
  # Continue.dev config for LiteLLM
  home.activation.continueConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p "$HOME/.continue"
        cat > "$HOME/.continue/config.json" << 'EOF'
    {
      "models": [
        {
          "title": "Gemini Flash (LiteLLM)",
          "provider": "openai",
          "model": "gemini-flash",
          "apiBase": "http://localhost:4000/v1",
          "apiKey": "not-needed"
        },
        {
          "title": "Gemini Pro (LiteLLM)",
          "provider": "openai",
          "model": "gemini-pro",
          "apiBase": "http://localhost:4000/v1",
          "apiKey": "not-needed"
        },
        {
          "title": "Qwen Coder (LiteLLM)",
          "provider": "openai",
          "model": "qwen-coder",
          "apiBase": "http://localhost:4000/v1",
          "apiKey": "not-needed"
        },
        {
          "title": "Qwen Coder (Ollama Direct)",
          "provider": "ollama",
          "model": "qwen2.5-coder:7b",
          "apiBase": "http://localhost:11434"
        }
      ],
      "tabAutocompleteModel": {
        "title": "Qwen Coder Autocomplete",
        "provider": "ollama",
        "model": "qwen2.5-coder:7b",
        "apiBase": "http://localhost:11434"
      },
      "allowAnonymousTelemetry": false
    }
    EOF
  '';

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions;
        [
          # Formatters & Editing
          aaron-bond.better-comments
          christian-kohler.path-intellisense
          codezombiech.gitignore
          esbenp.prettier-vscode
          foxundermoon.shell-format
          gruntfuggly.todo-tree
          irongeek.vscode-env
          redhat.vscode-yaml
          tamasfe.even-better-toml
          usernamehw.errorlens
          yzhang.markdown-all-in-one

          # Languages
          jnoortheen.nix-ide
          mkhl.direnv
          ms-python.isort
          ms-python.python
          ms-python.vscode-pylance
          nefrob.vscode-just-syntax
          thenuprojectcontributors.vscode-nushell-lang

          # DevOps
          ms-azuretools.vscode-docker
          ms-kubernetes-tools.vscode-kubernetes-tools
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh

          # Theme & Icons
          pkief.material-icon-theme

          # AI
          continue.continue
        ]
        ++ (with pkgs.vscode-utils; [
          (buildVscodeMarketplaceExtension {
            mktplcRef = {
              publisher = "BeardedBear";
              name = "beardedtheme";
              version = "10.1.0";
              sha256 = "0c0kcl08j8ii65h5mkpgssgqgshhkf49adgxd5xh1klx8qn2zjgc";
            };
          })
        ]);

      userSettings = {
        # ===== Editor =====
        "editor.bracketPairColorization.enabled" = true;
        "editor.fontFamily" = "'Maple Mono NF', 'MesloLGS NF', 'FiraCode Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 16;
        "editor.formatOnSave" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.quickSuggestions" = {
          comments = false;
          other = true;
          strings = true;
        };
        "editor.rulers" = [
          80
          120
        ];

        # ===== Files =====
        "files.autoSave" = "afterDelay";
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;
        "files.exclude" = {
          "**/.devenv" = true;
          "**/.direnv" = true;
          "**/node_modules" = true;
          "**/target" = true;
        };

        # ===== Git =====
        "git.autofetch" = true;
        "git.enableCommitSigning" = true;
        "github.gitProtocol" = "ssh";

        # ===== Terminal =====
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.fontFamily" = "MesloLGS NF";
        "terminal.integrated.scrollback" = 100000;

        # ===== Workbench =====
        "workbench.colorTheme" = "Bearded Theme Arc Reversed";
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.startupEditor" = "none";

        # ===== MCP Configuration =====
        "chat.mcp.discovery.enabled" = true;
        "chat.mcp.configPath" = "/etc/mcp/config.json";

        # ===== Continue.dev (LiteLLM) =====
        "continue.enableTabAutocomplete" = true;
        "continue.telemetryEnabled" = false;

        # ===== Language: Nix =====
        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
        "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.tabSize" = 2;
        };

        # ===== Language: Python =====
        "python.defaultInterpreterPath" = "${pkgs.python3}/bin/python3";
        "python.languageServer" = "Pylance";
        "[python]"."editor.defaultFormatter" = "ms-python.python";

        # ===== Language: YAML & Kubernetes =====
        "[yaml]" = {
          "editor.tabSize" = 2;
        };
        "yaml.schemas" = {
          "kubernetes" = [
            "k3s/*.yaml"
            "k8s/*.yaml"
          ];
        };

        # ===== Remote SSH =====
        "remote.SSH.remotePlatform" = {
          "192.168.1.118" = "linux";
          "192.168.1.132" = "linux";
          "192.168.1.165" = "linux";
        };

        # ===== Privacy & Telemetry =====
        "telemetry.telemetryLevel" = "off";
        "redhat.telemetry.enabled" = false;
        "update.mode" = "none";
      };
    };
  };
}
