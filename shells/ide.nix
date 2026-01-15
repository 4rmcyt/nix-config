{pkgs, ...}: let
  zellijLayout = pkgs.writeText "ide-layout.kdl" ''
    layout {
        pane split_direction="vertical" {
            pane size="65%" {
                pane command="hx" {
                    args "."
                }
            }
            pane size="35%" {
                pane command="zsh" {
                    args "-i" "-c" "gemini chat; exec zsh"
                }
            }
        }
        pane size=1 borderless=true {
            plugin location="zellij:compact-bar"
        }
    }
  '';
  zellijConfig = pkgs.writeText "ide-config.kdl" ''
    mouse_mode true
    copy_on_select true
  '';
in
  pkgs.mkShell {
    name = "terminal-ide";

    packages = with pkgs; [
      helix
      zellij
      gemini-cli
      zsh
    ];

    shellHook = ''
      echo "🚀 Terminal IDE Environment"
      echo "Run 'ide' to start the full environment."

      alias ide="zellij --layout ${zellijLayout} --config ${zellijConfig}"
    '';
  }
