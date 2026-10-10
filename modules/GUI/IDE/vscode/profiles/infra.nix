{pkgs}: {
  extensions = with pkgs.vscode-marketplace; [
    opentofu.vscode-opentofu
    ms-kubernetes-tools.vscode-kubernetes-tools
  ];
  settings = {};
}
