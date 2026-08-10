# nixos-config/treefmt.nix
{pkgs, ...}: {
  projectRootFile = "flake.nix";
  programs = {
    alejandra = {
      enable = true;
      includes = ["*.nix"];
      package = pkgs.alejandra;
    };
    deadnix = {
      enable = true;
      includes = ["*.nix"];
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
      includes = [".justfile"];
      package = pkgs.just;
    };
    prettier = {
      enable = true;
      # *.yaml/*.yml intentionally NOT here — yamlfmt already claims those
      # below. Both formatters racing on the same file caused treefmt's
      # mtime-staleness check to flag it as "changed underneath us" on
      # every CI run (confirmed live, always .trivyignore.yaml).
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
      ];
      package = pkgs.prettier;
    };
    rustfmt = {
      enable = true;
      includes = ["*.rs"];
      package = pkgs.rustfmt;
    };
    shellcheck = {
      enable = true;
      includes = [
        "*.bash"
        "*.envrc"
        "*.envrc.*"
        "*.sh"
      ];
      package = pkgs.shellcheck;
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
      includes = ["*.nix"];
      package = pkgs.statix;
    };
    terraform = {
      enable = true;
      package = pkgs.opentofu;
    };
    toml-sort = {
      enable = true;
      includes = ["*.toml"];
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
    ".gitignore"
  ];
}
