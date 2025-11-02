{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    # User settings and extensions
    profiles.default = {
      extensions = with pkgs.vscode-extensions;
        [
          # Formatters
          esbenp.prettier-vscode
          foxundermoon.shell-format
          redhat.vscode-yaml
          tamasfe.even-better-toml

          # Languages
          jnoortheen.nix-ide
          ms-python.python
          nefrob.vscode-just-syntax
          thenuprojectcontributors.vscode-nushell-lang

          # Git & SCM
          github.copilot
          github.copilot-chat
          anthropic.claude-code
        ]
        ++ (with pkgs.vscode-utils; [
          # Extensions from marketplace
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
          (buildVscodeMarketplaceExtension {
            mktplcRef = {
              publisher = "ibecker";
              name = "treefmt-vscode";
              version = "2.2.1";
              sha256 = "1ll7i4xfv4744d5xg3jcpcpi2b048qla1b95fi3sfnhkgk788k6y";
            };
          })
        ]);

      userSettings = {
        # ===== Editor Settings =====
        "editor.bracketPairColorization.enabled" = true;
        "editor.defaultFormatter" = "ibecker.treefmt-vscode";
        "editor.formatOnSave" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.rulers" = [
          80
          120
        ];

        # ===== File Settings =====
        "files.autoSave" = "afterDelay";
        "files.eol" = "\n";
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;

        # ===== Workbench Settings =====
        "workbench.colorTheme" = "Bearded Theme Arc Reversed";
        "workbench.editor.enablePreview" = false;
        "workbench.editor.limit.perEditorGroup" = true;
        "workbench.iconTheme" = "bearded-icons";
        "workbench.startupEditor" = "none";

        # ===== Explorer Settings =====
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        # ===== Diff Editor Settings =====
        "diffEditor.ignoreTrimWhitespace" = true;

        # ===== Terminal Settings =====
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.defaultProfile.osx" = "zsh";
        "terminal.integrated.fontFamily" = "MesloLGS NF";
        "terminal.integrated.tabs.defaultColor" = "terminal.ansiBlack";

        # ===== Git Settings =====
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableCommitSigning" = true;
        "git.enableSmartCommit" = true;
        "git.ignoreRebaseWarning" = true;
        "github.gitProtocol" = "ssh";

        # ===== Security Settings =====
        "security.allowedUNCHosts" = ["wsl.localhost"];
        "security.workspace.trust.untrustedFiles" = "prompt";

        # ===== Remote SSH Settings =====
        "remote.SSH.remotePlatform" = {
          "192.168.1.165" = "linux";
          "192.168.1.125" = "linux";
          "wsl.localhost" = "linux";
        };

        # ===== Language-Specific Settings =====

        # Nix
        "[nix]"."editor.defaultFormatter" = "ibecker.treefmt-vscode";
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          # nil will automatically find treefmt.toml and statix.toml
        };
        "nixEnvSelector.useFlakes" = true;

        # Shell
        "[shellscript]" = {
          "editor.defaultFormatter" = "foxundermoon.shell-format";
          "files.autoSave" = "afterDelay";
        };

        # YAML
        "[yaml]" = {
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.autoIndent" = "keep";
          "editor.insertSpaces" = true;
          "editor.quickSuggestions" = {
            "comments" = false;
            "other" = true;
            "strings" = true;
          };
          "editor.tabSize" = 2;
        };

        # Docker Compose
        "[dockercompose]" = {
          "editor.autoIndent" = "advanced";
          "editor.defaultFormatter" = "redhat.vscode-yaml";
          "editor.insertSpaces" = true;
          "editor.quickSuggestions" = {
            "comments" = false;
            "other" = true;
            "strings" = true;
          };
          "editor.tabSize" = 2;
        };

        # GitHub Actions
        "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";

        # JSON
        "[json]"."editor.defaultFormatter" = "vscode.json-language-features";
        "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";

        # JavaScript/TypeScript
        "[javascript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[javascriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[typescript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[typescriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";

        # Markdown
        "[markdown]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "files.trimTrailingWhitespace" = false;
        };

        # Python
        "[python]"."editor.defaultFormatter" = "ms-python.python";
        "python.analysis.enableTroubleshootMissingImports" = true;

        # TOML
        "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";

        # ===== Extension-Specific Settings =====

        # Treefmt
        "treefmt.debug" = false;

        # GitHub Copilot
        "github.copilot.nextEditSuggestions.enabled" = true;

        # Red Hat
        "redhat.telemetry.enabled" = false;
      };
    };
  };
}
