{
  lib,
  pkgs,
  config,
  ...
}: {
  programs = {
    carapace.enable = true;
    carapace.enableNushellIntegration = true;
    direnv.enable = true;
    direnv.enableNushellIntegration = false;

    nushell = {
      enable = true;
      plugins = with pkgs.nushellPlugins; [
        formats
        gstat
        highlight
        desktop_notifications
        query
        semver
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
            show_banner: false,
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
              {
                name: prepend_sudo_esc
                modifier: none
                keycode: esc
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

          # Auto-add SSH key if not already loaded
          if (ssh-add -l | complete | get exit_code) != 0 {
            ssh-add ~/.ssh/zeev
          }

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
        completions = {
          algorithm = "fuzzy";
          case_sensitive = false;
          partial = true;
          quick = true;
        };
        history = {
          file_format = "sqlite";
          isolation = true;
          max_size = 1000000;
        };
        show_banner = true;
      };
      shellAliases = {
        # "e" = "$EDITOR";
        # "ns" = "nix shell nixpkgs#";
        "_" = "doas";
        "clr" = "clear";
        "ctl" = "systemctl";
        "ctldrd" = "systemctl daemon-reload";
        "ctlfailed" = "systemctl --failed --all";
        "ctlrf" = "systemctl reset-failed";
        "ctlrt" = "systemctl restart";
        "ctls" = "systemctl status";
        "ctlsp" = "systemctl stop";
        "ctlst" = "systemctl start";
        "ctlu" = "systemctl --user";
        "ctlurt" = "systemctl --user restart";
        "ctlus" = "systemctl --user status";
        "ctlusp" = "systemctl --user stop";
        "ctlust" = "systemctl --user start";
        "j" = "journalctl";
        "ju" = "journalctl -xe -u";
        "juu" = "journalctl -xe --user-unit";
        "l" = "ls -a";
        "ll" = "ls -la";
        "man" = "pinfo";
        "nb" = "nix build";
        "nbf" = "nix-fast-build --flake";
        "nbfc" = "nix-fast-build --skip-cached --flake";
        "ncg" = "_ nix-collect-garbage";
        "ncgd" = "_ nix-collect-garbage -d";
        "nd" = "nix develop -c zsh";
        "nr" = "nix run";
        "nsp" = "nix-shell --run zsh -p";
        "q" = "qalc";
        "rcp" = "rsync -ah --partial --no-whole-file --info=progress2";
        "redd" = "systemctl --user stop gammastep.service &";
        "rede" = "systemctl --user start gammastep.service &";
        "rrcp" = "_ rsync -ah --partial --no-whole-file --info=progress2";
        "show-packages" = "_ nix-store -q --references /run/current-system/sw";
        "steam-gamescope" = "gamescope -b --steam -- steam -pipewire-dmabuf";
        "t" = "trans";
        "weather" = "curl wttr.in/Volzhskiy";
      };
    };
  };
}
