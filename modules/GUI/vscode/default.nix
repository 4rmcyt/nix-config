{
  pkgs,
  inputs,
  config,
  ...
}:
{
  # This top-level flag tells Home Manager to load the vscode module
  programs.vscode.enable = true;

  # Now that the module is loaded, these definitions will be valid
  programs.vscode.package = pkgs.vscode-fhs;
  programs.vscode.extensions = with pkgs.vscode-extensions;
  [
    # --- Nix ---
    jnoortheen.nix-ide
    ibecker.treefmt-vscode

    # --- Formatting & Linters ---
    esbenp.prettier-vscode
    foxundermoon.shell-format
    redhat.vscode-yaml
    tamasfe.even-better-toml
    tobiashochguertel.just-formatter

    # --- Git & SCM ---
    github.copilot
    github.copilot-chat
    gitlab.gitlab-workflow

    # --- Themes & UI ---
    BeardedBear.bearded-theme
    BeardedBear.bearded-icons
    oderwat.indent-rainbow

    # --- Other Tools ---
  ];

  programs.vscode.settings = {
    # --- General Editor & Git ---
    "editor.formatOnSave" = true;
    "editor.defaultFormatter" = "ibecker.treefmt-vscode";
    "files.autoSave" = "afterDelay";
    "files.eol" = "\n";
    "diffEditor.ignoreTrimWhitespace" = true;
    "explorer.confirmDelete" = false;
    "explorer.confirmDragAndDrop" = false;
    "workbench.startupEditor" = "none";
    "workbench.editor.limit.perEditorGroup" = true;
    "workbench.editor.enablePreview" = false;
    "git.enableCommitSigning" = true;
    "git.autofetch" = true;
    "git.enableSmartCommit" = true;
    "git.confirmSync" = false;
    "git.ignoreRebaseWarning" = true;
    "github.gitProtocol" = "ssh";

    # --- Theme ---
    "workbench.colorTheme" = "Bearded Theme Arc Reversed";
    "workbench.iconTheme" = "bearded-icons";

    # --- Terminal ---
    "terminal.integrated.fontFamily" = "MesloLGS NF";
    "terminal.integrated.defaultProfile.linux" = "zsh";
    "terminal.integrated.shell.osx" = "/bin/zsh";
    "terminal.integrated.tabs.defaultColor" = "terminal.ansiBlack";

    # --- Nix (nil + treefmt) ---
    "[nix]" = {
      "editor.defaultFormatter" = "ibecker.treefmt-vscode";
    };
    "nix.serverPath" = "nil";
    "nix.serverSettings" = {
      # nil will automatically find treefmt.toml and statix.toml
    };
    "nixEnvSelector.useFlakes" = true;
    "treefmt.debug" = true;

    # --- Language-Specific ---
    "[shellscript]" = {
      "files.autoSave" = "afterDelay";
      "editor.defaultFormatter" = "foxundermoon.shell-format";
    };
    "[yaml]" = {
      "editor.insertSpaces" = true;
      "editor.tabSize" = 2;
      "editor.autoIndent" = "keep";
      "diffEditor.ignoreTrimWhitespace" = false;
      "editor.defaultColorDecorators" = "never";
      "editor.quickSuggestions" = {
        "strings" = true;
        "other" = true;
        "comments" = false;
      };
    };
    "[dockercompose]" = {
      "editor.insertSpaces" = true;
      "editor.tabSize" = 2;
      "editor.autoIndent" = "advanced";
      "editor.quickSuggestions" = {
        "other" = true;
        "comments" = false;
        "strings" = true;
      };
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "[github-actions-workflow]" = {
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "vscode.json-language-features";
    };
    "yaml.schemas" = {
      "file:///home/zeev/.vscode/extensions/continue.continue-1.2.7-linux-x64/config-yaml-schema.json" = [
        ".continue/**/*.yaml"
      ];
    };

    # --- Other ---
    "redhat.telemetry.enabled" = true;
    "python.analysis.enableTroubleshootMissingImports" = true;
    "github.copilot.nextEditSuggestions.enabled" = true;
    "remote.SSH.remotePlatform" = {
      "192.168.1.165" = "linux";
      "192.168.1.125" = "linux";
      "wsl.localhost" = "linux";
    };
    "security.workspace.trust.untrustedFiles" = "open";
    "security.allowedUNCHosts" = [
      "wsl.localhost"
    ];
  };

  programs.vscode.user-data-dir = "${config.xdg.configHome}/Code";

  programs.vscode.settingsSync = {
    enable = true;
    ignoredExtensions = [
    ];
  };
}