{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = lib.mkBefore (
    with pkgs; [
      btop
      cpuid
      uutils-coreutils
      uutils-util-linux
      uutils-tar
      uutils-login
      uutils-procps
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
      wget
      bat
      jq
      sqlite
      taplo
      reptyr
      xmlstarlet
      busybox

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
      nixfmt
      optinix
      prettier
      pinentry-tty
      rustfmt
      shfmt
      sops
      statix
      toml-sort
      treefmt
      vulnix
      yamlfmt

      gnupg
      ssh-to-age
      libargon2

      git
      git-crypt
      delta
      gh
      gh-dash
      glab

      cht-sh
      fastfetch
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

      bind
      gping
      httpie
      hyperfine
      sipcalc
      sshfs
      yq-go
      ethtool
      wakeonlan

      ffmpeg
      rclone

      docker-compose
      kubectl
      krew
      kubie
      kind
      kubent
      kubebuilder
      kubernetes-helm

      cue
      golangci-lint

      nodejs_22

      python3
      uv

      rustup

      kitty.terminfo
      wezterm.terminfo
    ]
  );
}
