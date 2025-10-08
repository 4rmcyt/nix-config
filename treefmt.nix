# nixos-config/treefmt.nix
{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    alejandra = {
      enable = true;
      includes = [ "*.nix" ];
      package = pkgs.alejandra;
    };
    deadnix = {
      enable = true;
      includes = [ "*.nix" ];
      package = pkgs.deadnix;
    };
    dockfmt = {
      enable = true;
      includes = [
        "*.Dockerfile"
        "docker-compose.yml"
      ];
      package = pkgs.dockfmt;
    };
    just = {
      enable = true;
      includes = [ ".justfile" ];
      package = pkgs.just;
    };
    nixfmt = {
      enable = true;
      includes = [ "*.nix" ];
      package = pkgs.nixfmt-rfc-style;
    };
    prettier = {
      enable = true;
      includes = [
        "*.cjs"
        "*.css"
        "*.html"
        "*.js"
        "*.json"
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
      package = pkgs.prettier;
    };
    rustfmt = {
      enable = true;
      includes = [ "*.rs" ];
      package = pkgs.rustfmt;
    };
    shfmt = {
      enable = true;
      includes = [
        "*.bash"
        "*.envrc"
        "*.envrc.*"
        "*.sh"
      ];
      package = pkgs.shfmt;
    };
    statix = {
      enable = true;
      includes = [ "*.nix" ];
      package = pkgs.statix;
    };
    toml-sort = {
      enable = true;
      includes = [ "*.toml" ];
      package = pkgs.toml-sort;
    };
    yamlfmt = {
      enable = true;
      includes = [
        "*.yaml"
        "*.yml"
      ];
      package = pkgs.yamlfmt;
    };
  };

  settings.global.excludes = [
    "*.age"
    "*.clan-flake"
    "*.code-workspace"
    "*.desktop"
    "*.jpeg"
    "*.list"
    "*.png"
    "*.pub"
    "*.toml"
    "*.typed"
    "secrets/*"
  ];
}
