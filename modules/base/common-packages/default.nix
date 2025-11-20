{
  lib,
  pkgs,
  ...
}: {
  # Common system packages shared across all hosts
  # Use lib.mkDefault to allow hosts to override if needed
  environment.systemPackages = lib.mkBefore (
    with pkgs; [
      # =================================================================
      # Core System Utilities (alphabetical)
      # =================================================================
      btop
      curl
      direnv
      dockerfile-language-server
      git
      git-crypt
      gnumake
      htop
      just-lsp
      mc
      neofetch
      nh
      nix-fast-build
      nix-output-monitor
      nixos-rebuild-ng
      nodejs
      openssl
      p7zip
      pciutils
      prek
      namaka
      unzip
      usbutils
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
      neovim
      nix-diff
      nix-index
      nixfmt
      nufmt
      nixfmt-rfc-style
      nodePackages.prettier
      pinentry-tty
      rustfmt
      shfmt
      sops
      statix
      toml-sort
      treefmt
      yamlfmt
      zsh-powerlevel10k

      # =================================================================
      # Security & Secrets Management (alphabetical)
      # =================================================================
      gnupg
      ssh-to-age
    ]
  );
}
