# nixos-config/treefmt.nix
_:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt = {
      enable = true;
    };
    alejandra = {
      enable = false;
    };
    deadnix = {
      enable = true;
    };
    statix = {
      enable = true;
    };
    shfmt = {
      enable = true;
    };
    just = {
      enable = true;
    };
    rustfmt = {
      enable = true;
    };
    yamlfmt = {
      enable = true;
    };
    toml-sort = {
      enable = true;
    };
    dockfmt = {
      enable = true;
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
  };
}
# Remove any JSON content below this line
