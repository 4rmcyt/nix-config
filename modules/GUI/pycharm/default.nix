{ pkgs, ... }:
let
  pycharm-base = pkgs.jetbrains.pycharm-community.override {
    vmopts = ''
      -Dawt.toolkit.name=WLToolkit
      -Dsun.java2d.uiScale=2
    '';
  };
  pycharm-with-plugins = pkgs.jetbrains.plugins.addPlugins pycharm-base [
    "codeium.codeium"
  ];
in
{
  home.packages = [
    pycharm-with-plugins
    pkgs.codeium # Language server for Codeium plugin
  ];
}
