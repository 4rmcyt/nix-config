{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = [
    pkgs.sops
    pkgs.age
    pkgs.git
    pkgs.just
    pkgs.nixfmt-rfc-style
    pkgs.deadnix
    pkgs.shfmt
    pkgs.cachix
  ];
}