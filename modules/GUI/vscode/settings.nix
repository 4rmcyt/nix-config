{
  osConfig ? null,
  lib,
  ...
}: {
  programs.vscode.profiles.default.userSettings = {
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
    "editor.defaultFormatter" = "ibecker.treefmt-vscode";
    "editor.formatOnSave" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.rulers" = [80 120];

    # ===== File Settings =====
    "files.autoSave" = "afterDelay";
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
    "workbench.settings.applyToAllProfiles" = [];
    "workbench.settings.useSplitJSON" = true;
    "settingsSync.keybindingsPerPlatform" = false; # Disable settings sync writes
    "extensions.ignoreRecommendations" = true;

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
    "update.mode" = "none";

    # ===== Extension-Specific Settings =====
    # Disable Copilot, use Continue instead
    "github.copilot.enable" = {
      "*" = false;
    };
    "github.copilot.nextEditSuggestions.enabled" = false;

    # Continue settings
    "continue.enableTabAutocomplete" = true;
    "continue.showInlineTip" = false;

    # Use Continue for git commit messages
    "git.experimental.commitMessageProvider" = "continue.continue";

    "redhat.telemetry.enabled" = false;

    "yaml.schemas" = {
      "kubernetes" = [
        "k3s/*.yaml"
        "k8s/*.yaml"
      ];
    };
  };
}
