{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = lib.mkBefore (
    with pkgs; [
      # =================================================================
      # Core System Utilities
      # =================================================================
      btop
      cpuid
      uutils-coreutils
      curl
      duf
      eza
      fd
      findutils
      gawk
      gnugrep
      gnumake
      gnused
      gnutar
      gzip
      mc
      moreutils
      openssl
      p7zip
      unrar
      nvme-cli
      pciutils
      procs
      ripgrep
      unixtools.watch
      unzip
      usbutils
      neovim
      wget
      bat
      jq
      sqlite
      taplo
      reptyr
      xmlstarlet

      # =================================================================
      # Development & Nix Tools
      # =================================================================
      age
      alejandra
      cachix
      cmake-format
      comma
      deadnix
      dockfmt
      dockerfile-language-server
      just
      just-lsp
      jsonnet-language-server
      namaka
      nh
      nil
      nixd
      nix-diff
      nix-fast-build
      nix-output-monitor
      nixos-rebuild-ng
      nvd
      nix-sweep
      optinix
      prettier
      pinentry-tty
      rustfmt
      shfmt
      sops
      statix
      toml-sort
      treefmt
      yamlfmt

      # =================================================================
      # Security & Secrets Management
      # =================================================================
      gnupg
      ssh-to-age
      libargon2

      # =================================================================
      # Git & Version Control
      # =================================================================
      git
      git-crypt
      delta
      gh
      gh-dash
      glab

      # =================================================================
      # Productivity & Terminal Tools
      # =================================================================
      cht-sh
      fblog
      graph-easy
      grc
      mask
      mob
      presenterm
      slides
      termdown
      tmate
      viddy
      ytt
      zk

      # =================================================================
      # Network & System Analysis
      # =================================================================
      gping
      httpie
      hyperfine
      sipcalc
      sshfs
      yq-go
      ethtool
      wakeonlan

      # =================================================================
      # Media & File Processing
      # =================================================================
      ffmpeg
      rclone

      # =================================================================
      # Infrastructure & DevOps
      # =================================================================
      docker-compose
      kubectl
      krew
      kubie
      kind
      kubent
      kubebuilder
      kubernetes-helm

      # =================================================================
      # Programming Languages & Runtimes
      # =================================================================
      ## Golang
      cue
      golangci-lint

      ## Node/JavaScript
      nodejs_22

      ## Python
      python3
      uv

      ## Rust
      rustup

      # =================================================================
      # Terminal compatibility (SSH sessions)
      # =================================================================
      kitty.terminfo
      wezterm.terminfo
    ]
  );
}
