_: {
  programs.vscode.profiles.default.userSettings = {
    # ===== Nix =====
    "[nix]" = {
      "editor.tabSize" = 2;
      "editor.detectIndentation" = true;
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
    };
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
    "nix.serverSettings" = {
      formatting.command = ["alejandra"];
    };
    "nix.formatterPath" = "alejandra";
    "nixEnvSelector.useFlakes" = true;

    # ===== Shell =====
    "[shellscript]" = {
      "editor.defaultFormatter" = "foxundermoon.shell-format";
      "files.autoSave" = "afterDelay";
    };

    # ===== YAML =====
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

    # ===== Docker Compose =====
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

    # ===== GitHub Actions =====
    "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";

    # ===== JSON =====
    "[json]"."editor.defaultFormatter" = "vscode.json-language-features";
    "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";

    # ===== JavaScript/TypeScript =====
    "[javascript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[javascriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[typescript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[typescriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";

    # ===== Markdown =====
    "[markdown]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "files.trimTrailingWhitespace" = false;
    };

    # ===== Python =====
    "[python]"."editor.defaultFormatter" = "ms-python.python";
    "python.analysis.enableTroubleshootMissingImports" = true;

    # ===== TOML =====
    "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";
  };
}
