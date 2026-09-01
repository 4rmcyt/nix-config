{
  osConfig ? null,
  config,
  lib,
  pkgs,
  ...
}: let
  mcpServerNames = builtins.attrNames config.programs.mcp.servers;
  mcpList = lib.concatMapStringsSep "\n" (name: "- `${name}`") mcpServerNames;

  settings = {
    # ===== Editor Settings =====
    "password-store" = "gnome-libsecret";
    "editor.fontFamily" = "'Maple Mono NF', 'MesloLGS NF', 'FiraCode Nerd Font', monospace";
    "editor.fontLigatures" = true;
    "editor.fontSize" = 16;
    "editor.quickSuggestions" = {
      "other" = true;
      "comments" = false;
      "strings" = true;
    };
    "editor.bracketPairColorization.enabled" = true;
    "editor.formatOnSave" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.rulers" = [
      80
      120
    ];

    # ===== File Settings =====
    "files.autoSave" = "afterDelay";
    "files.autoSaveDelay" = 1000;
    "files.enableTrash" = false;
    "files.eol" = "\n";
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "files.trimTrailingWhitespace" = true;
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

    # ===== Workbench Settings =====
    "workbench.colorTheme" = "Kanagawa";
    "workbench.editor.enablePreview" = false;
    "workbench.editorAssociations" = {
      "*.md" = "vscode.markdown.preview.editor";
    };
    "vim.enable" = false;
    "workbench.editor.limit.perEditorGroup" = true;
    "workbench.iconTheme" = "material-icon-theme";
    "workbench.startupEditor" = "none";
    "workbench.settings.applyToAllProfiles" = [];

    # ===== Explorer Settings =====
    "explorer.confirmDelete" = false;
    "explorer.confirmDragAndDrop" = false;

    # ===== Diff Editor Settings =====
    "diffEditor.ignoreTrimWhitespace" = true;

    # ===== Search Settings =====
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

    # ===== Window Settings =====
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

    # ===== Misc Settings =====
    "todo-tree.regex.regex" = "(//|#|<!--|;|/\\*|^|^[ \\t]*(-|\\d+.))\\s*($TAGS)|todo!";
    "extensions.autoCheckUpdates" = false;
    "update.mode" = "none";

    # ===== Extension-Specific Settings =====

    # Disable Copilot, use Continue instead
    "github.copilot.enable" = {
      "*" = false;
    };
    "github.copilot.nextEditSuggestions.enabled" = false;
    "github.copilot.chat.commitMessageGeneration.instructions" = [];
    "github.copilot.chat.generateCommitMessage" = false;

    "redhat.telemetry.enabled" = false;

    "claude.code.autoApplyEdits" = true;
    "claude.code.enableMCP" = true;
    "claude.code.terminal.shell" = "zsh";
    "claudeCode.hideOnboarding" = true;

    # Cline (Claude Dev) System Prompt
    "cline.customSystemPrompt" = ''
      # Role: Senior Systems Architect (zeev)
      # Environment: NixOS (Canada)

      ## Operational Rules
      - Priority: Always use NixOS-idiomatic solutions (Flakes, modules).
      - Brevity: Extreme brevity. No conversational filler.
      - Context: Primary configs are in /etc/nixos and /home/zeev/src/nix-config.

      ## Available MCP Servers
      ${mcpList}

      ## Tool Usage Guidelines
      - Use `sequential-thinking` for all complex architectural changes.
      - Use `mcp-nixos` to search packages before suggesting Nix installs.
      - Use `filesystem` for file operations within allowed directories.
      - Use `python` for code execution and package management tasks.
    '';

    # CommitCraft — local llama-cpp commit message generation
    "commitCraft.apiBaseUrl" = "http://127.0.0.1:8080/v1";
    "commitCraft.apiKey" = "dummy";
    "commitCraft.customModel" = "gemma-local";
    "commitCraft.style" = "conventional";
    "commitCraft.detail" = "concise";
    "commitCraft.language" = "English";

    # ===== Language-Specific Settings =====

    # Nix
    "[nix]" = {
      "editor.tabSize" = 2;
      "editor.detectIndentation" = true;
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
    };
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
    "nix.serverSettings" = {
      nil = {
        formatting.command = ["alejandra"];
      };
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

    "yaml.disableSchemaDetection" = [
      "**/.github/workflows/*.yml"
      "**/.github/workflows/*.yaml"
      "**/.gitea/workflows/*.yml"
      "**/.gitea/workflows/*.yaml"
      "**/.forgejo/workflows/*.yml"
      "**/.forgejo/workflows/*.yaml"
    ];

    "yaml.schemas" = {
      "kubernetes" = [
        "k3s/*.yaml"
        "k8s/*.yaml"
      ];
      "file:///home/zeev/.vscode/extensions/Continue.continue/config-yaml-schema.json" = [
        ".continue/**/*.yaml"
      ];
    };
  };
  settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON settings);
  settingsPath = ".config/VSCodium/User/settings.json";
in {
  home.activation.vscodeSettings = lib.hm.dag.entryAfter ["linkGeneration"] ''
    settings_dest="$HOME/${settingsPath}"
    $DRY_RUN_CMD mkdir -p "$(dirname "$settings_dest")"
    [[ -L "$settings_dest" ]] && $DRY_RUN_CMD rm "$settings_dest"
    $DRY_RUN_CMD cp ${settingsFile} "$settings_dest"
    $DRY_RUN_CMD chmod 644 "$settings_dest"
  '';
}
