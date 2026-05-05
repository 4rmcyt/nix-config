{
  osConfig ? null,
  config,
  lib,
  pkgs,
  ...
}:
let
  mcpServerNames = builtins.attrNames config.programs.mcp.servers;
  mcpList = lib.concatMapStringsSep "\n" (name: "- `${name}`") mcpServerNames;

  settings = {
    # ===== Editor Settings =====
    "editor.fontFamily" = "'Maple Mono NF', 'MesloLGS NF', 'FiraCode Nerd Font', monospace";
    "editor.fontLigatures" = true;
    "editor.fontSize" = 16;
    "editor.quickSuggestions" = {
      "other" = true;
      "comments" = false;
      "strings" = true;
    };
    "editor.bracketPairColorization.enabled" = true;
    # "editor.defaultFormatter" = "ibecker.treefmt-vscode"; # Extension temporarily removed
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
    "workbench.colorTheme" = "Bearded Theme Arc Reversed";
    "workbench.editor.enablePreview" = false;
    "workbench.editor.limit.perEditorGroup" = true;
    "workbench.iconTheme" = "material-icon-theme";
    "workbench.startupEditor" = "none";
    "workbench.settings.applyToAllProfiles" = [ ];
    "workbench.settings.useSplitJSON" = true;

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
    "security.allowedUNCHosts" = [ "wsl.localhost" ];
    "security.workspace.trust.untrustedFiles" = "open";
    "telemetry.telemetryLevel" = "off";

    # ===== Remote SSH Settings =====
    "remote.SSH.remotePlatform" = {
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
    "github.copilot.chat.commitMessageGeneration.instructions" = [ ];
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
    "commitCraft.customModel" = "google_gemma-4-E4B-it-Q4_K_M";
    "commitCraft.style" = "conventional";
    "commitCraft.detail" = "concise";
    "commitCraft.language" = "English";

    "yaml.schemas" = {
      "kubernetes" = [
        "k3s/*.yaml"
        "k8s/*.yaml"
      ];
      "file:///home/zeev/.vscode/extensions/Continue.continue/config-yaml-schema.json" = [
        ".continue/**/*.yaml"
      ];
    };
    "sops.binPath" = "${pkgs.sops}/bin/sops";
    "sops.defaults.configPath" = ".sops.yaml";
    "sops.saveAsAsDefault" = false;
    "sops.tempDir" = "/tmp";
    "sops.logLevel" = "error";
  };

  settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON settings);
  settingsPath = ".config/Code/User/settings.json";
in
{
  # Seed settings.json on first activation only — VSCode owns the file after that.
  home.activation.vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dest="$HOME/${settingsPath}"
    # Remove symlink (leftover from older HM approach) so HM backup won't conflict
    if [ -L "$settings_dest" ]; then
      $DRY_RUN_CMD rm "$settings_dest"
    fi
    # Remove stale HM backup so HM can re-backup without failing
    $DRY_RUN_CMD rm -f "$settings_dest.hm-backup"
    if [ ! -f "$settings_dest" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$settings_dest")"
      $DRY_RUN_CMD cp ${settingsFile} "$settings_dest"
      $DRY_RUN_CMD chmod 644 "$settings_dest"
    fi
  '';
}
