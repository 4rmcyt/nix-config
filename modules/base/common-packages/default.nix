{
  lib,
  pkgs,
  ...
}: {
  # Common system packages shared across all hosts
  # Use lib.mkDefault to allow hosts to override if needed
  environment.systemPackages = lib.mkBefore (with pkgs; [
    # =================================================================
    # Core System Utilities (alphabetical)
    # =================================================================
    btop
    curl
    git
    git-crypt
    htop
    mc
    openssl
    pciutils
    unzip
    vim
    wget

    # =================================================================
    # Development & Nix Tools (alphabetical)
    # =================================================================
    age
    alejandra
    cachix
    cmake-format
    deadnix
    dockfmt
    helix
    just
    nix-diff
    nixfmt-rfc-style
    nodePackages.prettier
    rustfmt
    shfmt
    sops
    statix
    toml-sort
    yamlfmt

    # =================================================================
    # Security & Secrets Management (alphabetical)
    # =================================================================
    gnupg
    ssh-to-age
  ]);
}
