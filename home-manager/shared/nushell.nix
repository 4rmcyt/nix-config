{
  lib,
  pkgs,
  config,
  ...
}: {
  programs = {
    nushell = {
      enable = true;
      plugins = with pkgs.nushellPlugins; [
        semver
        query
        highlight
        gstat
        formats
      ];
      configFile = {
        text = ''
          # Common ls aliases and sort them by type and then name
          # Inspired by https://github.com/nushell/nushell/issues/7190
          def lla [...args] { ls -la ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
          def la  [...args] { ls -a  ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
          def ll  [...args] { ls -l  ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
          def l   [...args] { ls     ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }

          # Completions
          # mainly pieced together from https://www.nushell.sh/cookbook/external_completers.html

          # carapce completions https://www.nushell.sh/cookbook/external_completers.html#carapace-completer
          # + fix https://www.nushell.sh/cookbook/external_completers.html#err-unknown-shorthand-flag-using-carapace
          # enable the package and integration bellow
          let carapace_completer = {|spans: list<string>|
            carapace $spans.0 nushell ...$spans
            | from json
            | if ($in | default [] | where value == $"($spans | last)ERR" | is-empty) { $in } else { null }
          }
          # some completions are only available through a bridge
          # eg. tailscale
          # https://carapace-sh.github.io/carapace-bin/setup.html#nushell
          $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

          # fish completions https://www.nushell.sh/cookbook/external_completers.html#fish-completer
          let fish_completer = {|spans|
            ${lib.getExe pkgs.fish} --command $'complete "--do-complete=($spans | str join " ")"'
            | $"value(char tab)description(char newline)" + $in
            | from tsv --flexible --no-infer
          }

          # zoxide completions https://www.nushell.sh/cookbook/external_completers.html#zoxide-completer
          let zoxide_completer = {|spans|
              $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
          }

          # multiple completions
          # the default will be carapace, but you can also switch to fish
          # https://www.nushell.sh/cookbook/external_completers.html#alias-completions
          let multiple_completers = {|spans|
            ## alias fixer start https://www.nushell.sh/cookbook/external_completers.html#alias-completions
            let expanded_alias = scope aliases
            | where name == $spans.0
            | get -o 0.expansion

            let spans = if $expanded_alias != null {
              $spans
              | skip 1
              | prepend ($expanded_alias | split row ' ' | take 1)
            } else {
              $spans
            }
            ## alias fixer end

            match $spans.0 {
              __zoxide_z | __zoxide_zi => $zoxide_completer
              _ => $carapace_completer
            } | do $in $spans
          }

          $env.config = {
            show_banner: true,
            completions: {
              case_sensitive: false # case-sensitive completions
              quick: true           # set to false to prevent auto-selecting completions
              partial: true         # set to false to prevent partial filling of the prompt
              algorithm: "fuzzy"    # prefix or fuzzy
              external: {
                enable: true
                max_results: 100
                completer: $multiple_completers
              }
            }
            keybindings: [
              {
                name: prepend_sudo
                modifier: alt
                keycode: char_/
                mode: emacs
                event: [
                  { edit: MoveToStart }
                  { edit: InsertString, value: "sudo " }
                  { edit: MoveToEnd }
                ]
              }
            ]
          }

          $env.config.hooks.command_not_found = source ${config.programs.nix-index.package}/etc/profile.d/command-not-found.nu

          $env.config.plugins.highlight.true_colors = true
          $env.config.plugins.highlight.theme = "3024-night"

          $env.REALNAME = "Redacted Name";
          $env.EMAIL = "redacted@example.com";
          $env.BROWSER = "firefox";
          $env.XDG_CONFIG_HOME = $"($env.HOME)/.config";
          $env.TODO_DIR = $"($env.HOME)/.todo";
          $env.PAGER = try { (which bat).0.cmd } catch { "less" };
          $env.BAT_PAGER = "less";
          $env.BAT_THEME = "gruvbox-dark";
          $env.PROMPT_INDICATOR_VI_INSERT = "⎆ ";
          $env.PROMPT_INDICATOR_VI_NORMAL = "⎌ ";
        '';
      };
      settings = {
        show_banner = true;
        completions = {
          case_sensitive = false;
          quick = true;
          partial = true;
          algorithm = "fuzzy";
        };
        history = {
          file_format = "sqlite";
          max_size = 1000000;
          isolation = true;
        };
      };
      shellAliases = {
        "l" = "ls -a";
        "ll" = "ls -la";
        "_" = "doas";
        "clr" = "clear";
        "rcp" = "rsync -ah --partial --no-whole-file --info=progress2";
        "rrcp" = "_ rsync -ah --partial --no-whole-file --info=progress2";
        "ncg" = "_ nix-collect-garbage";
        "ncgd" = "_ nix-collect-garbage -d";
        "weather" = "curl wttr.in/Volzhskiy";
        "rede" = "systemctl --user start gammastep.service &";
        "redd" = "systemctl --user stop gammastep.service &";
        "show-packages" = "_ nix-store -q --references /run/current-system/sw";
        # "ns" = "nix shell nixpkgs#";
        "nsp" = "nix-shell --run zsh -p";
        "nd" = "nix develop -c zsh";
        "nb" = "nix build";
        "nbf" = "nix-fast-build --flake";
        "nbfc" = "nix-fast-build --skip-cached --flake";
        "nr" = "nix run";
        # "e" = "$EDITOR";
        "q" = "qalc";
        "man" = "pinfo";
        "t" = "trans";
        "steam-gamescope" = "gamescope -b --steam -- steam -pipewire-dmabuf";
        # systemd
        "ctl" = "systemctl";
        "ctlsp" = "systemctl stop";
        "ctlst" = "systemctl start";
        "ctlrt" = "systemctl restart";
        "ctls" = "systemctl status";
        "ctlu" = "systemctl --user";
        "ctlusp" = "systemctl --user stop";
        "ctlust" = "systemctl --user start";
        "ctlurt" = "systemctl --user restart";
        "ctlus" = "systemctl --user status";
        "ctlfailed" = "systemctl --failed --all";
        "ctlrf" = "systemctl reset-failed";
        "ctldrd" = "systemctl daemon-reload";
        "j" = "journalctl";
        "ju" = "journalctl -xe -u";
        "juu" = "journalctl -xe --user-unit";
      };
    };
    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    # Disable automatic Nushell integration for direnv to avoid parse-time source errors
    # Direnv integration will be handled via the direnv hook in home-manager
    direnv.enable = true;
    direnv.enableNushellIntegration = false;
  };
}
