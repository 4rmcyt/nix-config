{pkgs, ...}: {
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
          github.copilot
          google.gemini-cli-vscode-ide-companion
        ]
        ++ (with pkgs.vscode-utils; [
          # Optimized Agent for VS Code
          (buildVscodeMarketplaceExtension {
            mktplcRef = {
              publisher = "rooveterinaryinc";
              name = "roo-cline";
              version = "3.2.14";
              sha256 = "sha256-R7R2CqfQJmN+Xp8LwZqE5O8uX/S3D5g5L8nS8L8L8L8=";
            };
          })
          (buildVscodeMarketplaceExtension {
            mktplcRef = {
              publisher = "Google";
              name = "geminicodeassist";
              version = "2.67.0";
              sha256 = "sha256-pAbAXPosrL+b5FmjaqGviaVR9rGTsgAgZqaU7EsPKLA=";
            };
          })
          (buildVscodeMarketplaceExtension {
            mktplcRef = {
              publisher = "BeardedBear";
              name = "beardedtheme";
              version = "10.1.0";
              sha256 = "0c0kcl08j8ii65h5mkpgssgqgshhkf49adgxd5xh1klx8qn2zjgc";
            };
          })
          (buildVscodeMarketplaceExtension {
            mktplcRef = {
              publisher = "BeardedBear";
              name = "beardedicons";
              version = "1.22.0";
              sha256 = "1aaxbrbss3ck9pab3fz55xkkwm1qc1dgq6aypfh7fl2qakfv0r0f";
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
        "editor.rulers" = [80 120];

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

        # ===== AI Routing (RouteLLM Integration via OpenAI API) =====
        "roo-cline.apiProvider" = "openai";
        "roo-cline.openAiBaseUrl" = "http://localhost:6000/v1";
        "roo-cline.openAiModelId" = "routellm";
        "geminicodeassist.project" = "inner-radius-484521-p2";

        # ===== System MCP Configuration =====
        "chat.mcp.discovery.enabled" = true;
        "chat.mcp.configPath" = "/etc/mcp/config.json"; # Points to our system-wide config

        # ===== Language: Nix =====
        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
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
        "[yaml]" = {"editor.tabSize" = 2;};
        "yaml.schemas" = {
          "kubernetes" = ["k3s/*.yaml" "k8s/*.yaml"];
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
