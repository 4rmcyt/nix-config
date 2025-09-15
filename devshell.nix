{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = [
    # Existing packages
    sops

    # Add missing formatters
    cmake-format
    nodePackages.prettier
    rustfmt

    # Other useful tools for your nix config
    nixfmt-rfc-style
    deadnix
    statix
  ];
}
