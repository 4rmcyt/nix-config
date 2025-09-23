# nixos-config/treefmt.nix
{pkgs, ...}: {
  projectRootFile = "flake.nix";
  programs = {
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
      includes = ["*.nix"];
    };
    alejandra = {
      enable = true;
      package = pkgs.alejandra;
      includes = ["*.nix"];
    };
    deadnix = {
      enable = true;
      package = pkgs.deadnix;
      includes = ["*.nix"];
    };
    statix = {
      package = pkgs.statix;
      enable = true;
      includes = ["*.nix"];
    };
    shfmt = {
      enable = true;
      package = pkgs.shfmt;
      includes = [
        "*.sh"
        "*.bash"
        "*.envrc"
        "*.envrc.*"
      ];
    };
    just = {
      enable = true;
      package = pkgs.just;
      includes = [".justfile"];
    };
    rustfmt = {
      enable = true;
      package = pkgs.rustfmt;
      includes = ["*.rs"];
    };
    yamlfmt = {
      enable = true;
      package = pkgs.yamlfmt;
      includes = [
        "*.yaml"
        "*.yml"
      ];
    };
    toml-sort = {
      enable = true;
      package = pkgs.toml-sort;
      includes = ["*.toml"];
    };
    dockfmt = {
      enable = true;
      package = pkgs.dockfmt;
      includes = [
        "*.Dockerfile"
        "docker-compose.yml"
      ];
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
    package = pkgs.prettier;
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
      "*.json"
      "*.yaml"
    ];
  };
}
