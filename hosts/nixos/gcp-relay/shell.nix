# Minimal zsh + starship without Home Manager; plugins from nixpkgs, no runtime fetches.
{
  lib,
  pkgs,
  ...
}: {
  programs.starship = {
    enable = true;
    presets = ["bracketed-segments"];
    settings = {
      git_status = {
        stashed = "";
        untracked = "";
        modified = builtins.fromJSON ''"\uEB43 "''; # nf-cod-request_changes
      };
      custom.nix = {
        detect_files = ["flake.nix"];
        symbol = builtins.fromJSON ''"\uF313 "''; # nf-linux-nixos
        format = "\\[[$symbol]($style)\\]";
        style = "bold blue";
      };
    };
  };

  programs.zsh = {
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # After syntax-highlighting (mkAfter = 1500), as substring-search requires.
    interactiveShellInit = lib.mkOrder 1600 ''
      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      bindkey '^f' autosuggest-accept
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      bindkey '^[w' kill-region

      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

      bindkey '\e[H' beginning-of-line
      bindkey '\e[F' end-of-line
      bindkey '\e[1~' beginning-of-line
    '';
  };
}
