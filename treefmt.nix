{ pkgs, ... }:
{

  projectRootFile = "flake.nix";
  programs.shellcheck.enable = true;

  programs.nixfmt.enable = true;
  programs.nixfmt.package = pkgs.nixfmt-rfc-style;
  programs.deadnix.enable = true;
  programs.alejandra.package = pkgs.alejandra;
  programs.statix.package = pkgs.statix;
  settings.global.excludes = [
    # Add this line to exclude the third-party input
    "secrets/*"
    "*.png"
    "*.jpeg"
    "*.yaml"
    "*.gitignore"
    ".vscode/*"
    "*.toml"
    "*.clan-flake"
    "*.code-workspace"
    "*.pub"
    "*.typed"
    "*.age"
    "*.list"
    "*.desktop"
  ];
  programs.prettier = {
    enable = true;
    includes = [
      "*.cjs"
      "*.css"
      "*.html"
      "*.js"
      "*.json5"
      "*.jsx"
      "*.mdx"
      "*.mjs"
      "*.scss"
      "*.ts"
      "*.tsx"
      "*.vue"
      "*.yaml"
      "*.yml"
    ];

  };
}
