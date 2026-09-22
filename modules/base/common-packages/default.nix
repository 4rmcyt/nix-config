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
      curl
      duf
      eza
      fd
      findutils
      gawk
      gnugrep
      gnumake
      gnused
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
      shh
      strace
      kernel-hardening-checker
      cachix
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

      git
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
      termdown
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
