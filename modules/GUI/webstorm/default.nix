{ pkgs, ... }:
{
  home.packages = [
    (pkgs.jetbrains.webstorm.override {
      vmopts = ''
        -Dawt.toolkit.name=WLToolkit
        -Dsun.java2d.uiScale=2
      '';
    })
    pkgs.codeium # Language server for Codeium plugin
  ];
}
