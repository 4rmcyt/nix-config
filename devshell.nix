{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [
    # SOPS for secrets management
    sops

    # Code formatters
    cmake-format
    nodePackages.prettier # This is the correct way to get prettier
    rustfmt
    nixfmt-rfc-style
    deadnix
    statix
    yamlfmt
    toml-sort
    shfmt
    just
    dockfmt
    alejandra

    # Development tools
    nix-diff
  ];
}
