{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (jetbrains.pycharm-oss.override {
      vmopts = ''
        -Dawt.toolkit.name=WLToolkit
        -Dsun.java2d.uiScale=2
      '';
    })
    codeium # Language server for Codeium plugin
  ];
}
