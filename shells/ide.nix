{pkgs, ...}: let
  zellijLayout = pkgs.writeText "ide-layout.kdl" ''
    layout {
        pane split_direction="vertical" {
            pane size="65%" {
                pane command="hx" {
                    args "."
                }
            }
            pane size="35%" split_direction="horizontal" {
                pane command="gemini" {
                    args "chat"
                }
                pane
            }
        }
        pane size=1 borderless=true {
            plugin location="zellij:compact-bar"
        }
    }
  '';
in
  pkgs.mkShell {
    name = "terminal-ide";

    packages = with pkgs; [
      helix
      zellij
      gemini-cli
    ];

    shellHook = ''
      echo "🚀 Terminal IDE Environment"
      echo "Run 'ide' to start the full environment."

      alias ide="zellij --layout ${zellijLayout}"
    '';
  }
