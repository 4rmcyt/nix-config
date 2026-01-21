{ pkgs, ... }:
{
  home.packages = [
    (pkgs.jetbrains.pycharm.override {
      vmopts = ''
        -Dawt.toolkit.name=WLToolkit
        -Dsun.java2d.uiScale=2
      '';
    })
  ];

  # Configure AI Assistant / Continue plugin if available for PyCharm via Nix
  # Currently, JetBrains AI configuration is mostly manual or via plugin settings files
  # stored in ~/.config/JetBrains/PyCharm*, which are mutable.
  # However, we can ensure the environment variables for local models are available.
}
