{pkgs}: {
  extensions = with pkgs.vscode-marketplace; [
    detachhead.basedpyright
    charliermarsh.ruff
  ];
  settings = {
    "[python]"."editor.defaultFormatter" = "charliermarsh.ruff";
    # Without ms-python, fromEnvironment crashes the extension (basedpyright#1188)
    "basedpyright.importStrategy" = "useBundled";
  };
}
