{pkgs}: {
  extensions = with pkgs.vscode-marketplace; [
    dbaeumer.vscode-eslint
    vitest.explorer
    ms-playwright.playwright
  ];
  settings = {};
}
