{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.vscode.profiles.default;
  configDir = "Code";
  userDir = "${config.xdg.configHome}/${configDir}/User";

  # List of files to make mutable
  filesToMakeMutable = lib.flatten [
    (lib.optional (cfg.userSettings != {}) "${userDir}/settings.json")
    (lib.optional (cfg.keybindings != []) "${userDir}/keybindings.json")
    (lib.optional (cfg.userTasks != {}) "${userDir}/tasks.json")
  ];

  # Generate the shell commands to replace symlinks with copies
  makeFileMutable = file: ''
    target="${file}"
    if [ -L "$target" ]; then
      real_source=$(readlink "$target")
      echo "Making mutable: $target"
      rm "$target"
      cp "$real_source" "$target"
      chmod u+w "$target"
    elif [ -f "$target" ]; then
      echo "Already mutable: $target"
    fi
  '';
in {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
      extensions = with pkgs.vscode-extensions;
        [
          # Formatters
          aaron-bond.better-comments
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
          ms-python.python
          nefrob.vscode-just-syntax
          thenuprojectcontributors.vscode-nushell-lang

          mkhl.direnv
          ms-azuretools.vscode-docker
          ms-kubernetes-tools.vscode-kubernetes-tools
          ms-python.isort
          ms-python.python
          ms-python.vscode-pylance
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          pkief.material-icon-theme
          tamasfe.even-better-toml
          usernamehw.errorlens
          yzhang.markdown-all-in-one

          # Git & SCM
          github.copilot

          # AI Code Assist
          Google.gemini-cli-vscode-ide-companion
        ]
        ++ (with pkgs.vscode-utils; [
          # Extensions from marketplace
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
        "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
        "[javascript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[javascriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[json]"."editor.defaultFormatter" = "vscode.json-language-features";
        "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";
        "[markdown]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "files.trimTrailingWhitespace" = false;
        };
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.detectIndentation" = true;
          "editor.tabSize" = 2;
        };
        "[python]"."editor.defaultFormatter" = "ms-python.python";
        "[shellscript]" = {
          "editor.defaultFormatter" = "foxundermoon.shell-format";
          "files.autoSave" = "afterDelay";
        };
        "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";
        "[typescript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[typescriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
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
        "chat.mcp.gallery.enabled" = true;
        "diffEditor.ignoreTrimWhitespace" = true;
        "editor.bracketPairColorization.enabled" = true;
        "editor.fontFamily" = "'Maple Mono NF', 'MesloLGS NF', 'FiraCode Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 16;
        "editor.formatOnSave" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.quickSuggestions" = {
          "comments" = false;
          "other" = true;
          "strings" = true;
        };
        "editor.rulers" = [80 120];
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;
        "extensions.autoCheckUpdates" = false;
        "extensions.ignoreRecommendations" = true;
        "files.autoSave" = "afterDelay";
        "files.enableTrash" = false;
        "files.eol" = "\n";
        "files.exclude" = {
          "**/.classpath" = true;
          "**/.devenv" = true;
          "**/.direnv" = true;
          "**/.factorypath" = true;
          "**/.project" = true;
          "**/.settings" = true;
        };
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;
        "files.watcherExclude" = {
          "**/.devenv" = true;
          "**/.direnv" = true;
        };
        "geminicodeassist.cloudcode.duetAI.project" = "";
        "geminicodeassist.project" = "inner-radius-484521-p2";
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableCommitSigning" = true;
        "git.enableSmartCommit" = true;
        "git.ignoreRebaseWarning" = true;
        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.gitProtocol" = "ssh";
        "http.systemCertificatesNode" = true;
        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "alejandra";
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          "formatting"."command" = ["alejandra"];
          "nix"."flake"."autoArchive" = true;
        };
        "python.analysis.enableTroubleshootMissingImports" = true;
        "redhat.telemetry.enabled" = false;
        "remote.SSH.remotePlatform" = {
          "192.168.1.118" = "linux";
          "192.168.1.132" = "linux";
          "192.168.1.165" = "linux";
          "wsl.localhost" = "linux";
        };
        "search.exclude" = {
          "**/.devenv" = true;
          "**/.direnv" = true;
        };
        "security.workspace.trust.untrustedFiles" = "open";
        "telemetry.telemetryLevel" = "off";
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.defaultProfile.osx" = "zsh";
        "terminal.integrated.fontFamily" = "MesloLGS NF";
        "terminal.integrated.fontWeight" = "500";
        "terminal.integrated.profiles.linux"."nu"."path" = "/etc/profiles/per-user/zeev/bin/nu";
        "terminal.integrated.scrollback" = 100000;
        "terminal.integrated.tabs.defaultColor" = "terminal.ansiBlack";
        "todo-tree.regex.regex" = "(//|#|<!--|;|/\\*|^|^[ \\t]*(-|\\d+.))\\s*($TAGS)|todo!";
        "update.mode" = "none";
        "window.autoDetectColorScheme" = false;
        "window.menuBarVisibility" = "visible";
        "window.titleBarStyle" = "custom";
        "workbench.colorTheme" = "Bearded Theme Arc Reversed";
        "workbench.editor.enablePreview" = false;
        "workbench.editor.limit.perEditorGroup" = true;
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.settings.applyToAllProfiles" = [];
        "workbench.startupEditor" = "none";
        "yaml.schemas"."kubernetes" = ["k3s/*.yaml" "k8s/*.yaml"];
      };
    };
  };

  # Make VS Code config files mutable (editable after generation)
  # This replaces the nix-store symlinks with writable copies after home-manager creates them
  home.activation.vscodeFileMutability = lib.hm.dag.entryAfter ["linkGeneration"] ''
    echo "Making VS Code config files mutable..."
    ${lib.concatMapStrings makeFileMutable filesToMakeMutable}
  '';
}
