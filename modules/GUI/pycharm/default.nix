{pkgs, ...}: {
  home.packages = with pkgs; [
    jetbrains.pycharm-oss
    codeium # Language server for Codeium plugin
  ];
}
