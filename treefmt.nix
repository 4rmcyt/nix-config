# nixos-config/treefmt.nix
{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    alejandra = {
      enable = true;
      package = pkgs.alejandra;
    };
    deadnix = {
      enable = true;
      package = pkgs.deadnix;
    };
    statix = {
      package = pkgs.statix;
      enable = true;
    };
    shfmt = {
      enable = true;
      package = pkgs.shfmt;
    };
    just = {
      enable = true;
      package = pkgs.just;
    };
    rustfmt = {
      enable = true;
      package = pkgs.rustfmt;
    };
  };
  settings.global.excludes = [
    "secrets/*"
    "*.png"
    "*.jpeg"
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
