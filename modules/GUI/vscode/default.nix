{
  pkgs,
  osConfig ? null,
  lib,
  ...
}: {
  # Continue extension configuration
  home.file.".continue/config.json".text = builtins.toJSON {
    models = [
      {
        title = "Gemini 2.5 Pro";
        provider = "google";
        model = "gemini-2.5-pro";
      }
      {
        title = "Gemini 2.5 Flash";
        provider = "google";
        model = "gemini-2.5-flash";
      }
      {
        title = "GLM-4.7-Flash (Local)";
        provider = "openai";
        model = "glm-4.7-flash";
        apiBase = "http://127.0.0.1:8080/v1";
        apiKey = "not-needed";
      }
    ];
    tabAutocompleteModel = {
      title = "GLM-4.7-Flash Autocomplete";
      provider = "openai";
      model = "glm-4.7-flash";
      apiBase = "http://127.0.0.1:8080/v1";
      apiKey = "not-needed";
    };
    experimental = {
      modelContextProtocolServers = [
        {
          name = "mcp-nixos";
          command = "nix";
          args = ["run" "github:utensils/mcp-nixos" "--"];
        }
        {
          name = "filesystem";
          command = "npx";
          args = ["-y" "@modelcontextprotocol/server-filesystem" "/etc/nixos" "/home/zeev/src/nix-config"];
        }
        {
          name = "sequential-thinking";
          command = "npx";
          args = ["-y" "@modelcontextprotocol/server-sequential-thinking"];
        }
        {
          name = "terraform";
          command = "npx";
          args = ["-y" "terraform-mcp-server"];
        }
        {
          name = "kubernetes";
          command = "uvx";
          args = ["-y" "mcp-server-kubernetes"];
        }
        {
          name = "memory";
          command = "npx";
          args = ["-y" "@modelcontextprotocol/server-memory"];
        }
        {
          name = "fetch";
          command = "npx";
          args = ["-y" "@modelcontextprotocol/server-fetch"];
        }
        {
          name = "chrome-devtools";
          command = "npx";
          args = ["-y" "chrome-devtools-mcp@latest"];
        }
        {
          name = "llama-cpp";
          command = "npx";
          args = ["-y" "mcp-server-openai" "--base-url" "http://127.0.0.1:8080/v1" "--api-key" "not-needed" "--model" "glm-4.7-flash"];
        }
      ];
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions;
        [
          # Formatters & Editing
          codezombiech.gitignore
          christian-kohler.path-intellisense
          gruntfuggly.todo-tree
          irongeek.vscode-env
          esbenp.prettier-vscode
          foxundermoon.shell-format
          redhat.vscode-yaml
          tamasfe.even-better-toml

          # Languages
          jnoortheen.nix-ide
          mkhl.direnv
          ms-python.isort
          ms-python.python
          ms-python.vscode-pylance
          nefrob.vscode-just-syntax

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
        "editor.fontFamily" = "'Maple Mono NF', 'MesloLGS NF', 'FiraCode Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 16;
        "editor.quickSuggestions" = {
          "other" = true;
          "comments" = false;
          "strings" = true;
        };
        "files.enableTrash" = false;
        "files.exclude" = {
          "**/.classpath" = true;
          "**/.devenv" = true;
          "**/.direnv" = true;
          "**/.factorypath" = true;
          "**/.project" = true;
          "**/.settings" = true;
        };
        "files.watcherExclude" = {
          "**/.devenv" = true;
          "**/.direnv" = true;
        };

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
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.startupEditor" = "none";
        "workbench.settings.applyToAllProfiles" = [];
        "extensions.ignoreRecommendations" = true;

        # ===== Explorer Settings =====
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        # ===== Diff Editor Settings =====
        "diffEditor.ignoreTrimWhitespace" = true;

        "search.exclude" = {
          "**/.devenv" = true;
          "**/.direnv" = true;
        };
        # ===== Terminal Settings =====
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.defaultProfile.osx" = "zsh";
        "terminal.integrated.fontFamily" = "MesloLGS NF";
        "terminal.integrated.tabs.defaultColor" = "terminal.ansiBlack";
        "terminal.integrated.fontWeight" = "500";
        "terminal.integrated.profiles.linux".nu.path = "/etc/profiles/per-user/zeev/bin/nu";
        "terminal.integrated.scrollback" = 100000;
        "todo-tree.regex.regex" = "(//|#|<!--|;|/\\*|^|^[ \\t]*(-|\\d+.))\\s*($TAGS)|todo!";
        "update.mode" = "none";
        "[nix]" = {
          "editor.tabSize" = 2;
          "editor.detectIndentation" = true;
        };
        "window.menuBarVisibility" = "visible";
        "window.titleBarStyle" = "custom";
        "window.autoDetectColorScheme" = false;

        # ===== Git Settings =====
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableCommitSigning" = true;
        "git.enableSmartCommit" = true;
        "git.ignoreRebaseWarning" = true;
        "github.gitProtocol" = "ssh";

        # ===== Security Settings =====
        "security.allowedUNCHosts" = ["wsl.localhost"];
        "security.workspace.trust.untrustedFiles" = "open";
        "telemetry.telemetryLevel" = "off";

        # ===== Remote SSH Settings =====
        "remote.SSH.remotePlatform" =
          {
            "wsl.localhost" = "linux";
          }
          // lib.optionalAttrs (osConfig != null && osConfig ? my.defaults) {
            "${osConfig.my.defaults.homeserver_lan}" = "linux";
            "${osConfig.my.defaults.matebook_wifi}" = "linux";
            "${osConfig.my.defaults.desktop_lan}" = "linux";
          };

        # ===== Language-Specific Settings =====

        # Nix
        "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          formatting.command = ["alejandra"];
        };
        "nix.formatterPath" = "alejandra";
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

        # GitHub Copilot
        "github.copilot.nextEditSuggestions.enabled" = true;

        # Red Hat
        "redhat.telemetry.enabled" = false;

        "yaml.schemas" = {
          "kubernetes" = [
            "k3s/*.yaml"
            "k8s/*.yaml"
          ];
        };
      };
    };
  };
}
