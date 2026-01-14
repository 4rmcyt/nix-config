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
      cpuid
      coreutils-full
      curl
      direnv
      duf # disk usage
      findutils
      gawk
      gnugrep
      gnumake
      gnused
      gnutar
      gzip
      htop
      mc
      neofetch
      openssl
      p7zip
      unrar
      pciutils
      procs # better ps
      unixtools.watch # watches commands
      unzip
      usbutils
      vim
      wget
      iw
      fh
      tailspin
      gomi
      jq
      taplo
      nix-output-monitor
      nvd

      # =================================================================
      # Development & Nix Tools (alphabetical)
      # =================================================================
      age
      alejandra
      asdf-vm # managing different versions
      cachix
      cmake-format
      comma # run nix binaries on demand
      deadnix
      dockfmt
      dockerfile-language-server
      helix
      just
      just-lsp
      jsonnet-language-server # grafana lsp
      namaka
      neovim
      nh
      nil
      nixd
      nix-diff
      nix-fast-build
      nix-index
      nixfmt
      nixos-rebuild-ng
      nodePackages.prettier
      nufmt
      pinentry-tty
      prek
      rustfmt
      shfmt
      sops
      statix
      toml-sort
      treefmt
      yamlfmt
      zsh-powerlevel10k
      nix-sweep

      # =================================================================
      # Security & Secrets Management (alphabetical)
      # =================================================================
      gnupg
      ssh-to-age

      # =================================================================
      # Git & Version Control (alphabetical)
      # =================================================================
      git
      git-crypt
      delta # pretty diff tool
      gh # github cli tool
      gh-dash
      glab # gitlab cli tool

      # =================================================================
      # Productivity & Terminal Tools (alphabetical)
      # =================================================================
      cht-sh # cheat sheet -> cht python read file
      fblog # json log viewer
      graph-easy # draw graphs in the terminal
      grc # colored log output
      mask # taskrunner
      mob # mob programming tool
      presenterm # presentation tool
      slides # terminal presentation tool
      tealdeer # community driven man pages
      termdown # terminal countdown
      tmate # share terminal via web
      viddy # terminal watch command
      ytt # yaml templating engine
      zk # zettelkasten

      # =================================================================
      # Network & System Analysis (alphabetical)
      # =================================================================
      dive # analyse docker images
      gping # ping with a graph
      httpie # awesome alternative to curl
      hyperfine # benchmark tool
      sipcalc # ip subnet calculator
      sshfs # mount folders via ssh
      yq-go # yaml, toml parser

      # =================================================================
      # Media & File Processing (alphabetical)
      # =================================================================
      ffmpeg # video editing and cutting
      rclone # sync files

      # =================================================================
      # Infrastructure & DevOps (alphabetical)
      # =================================================================
      opentofu
      terraform

      # =================================================================
      # Cloud Providers (alphabetical)
      # =================================================================
      awscli2
      s3cmd

      # =================================================================
      # Programming Languages & Runtimes
      # =================================================================

      ## Golang
      cue
      golangci-lint

      ## Kotlin
      gradle
      kotlin
      ktlint

      # ## Node/JavaScript
      # deno # node runtime
      # nodejs
      # nodePackages.npm

      # ## Python
      # poetry
      # python3
      # uv # workspace management tool

      ## Rust
      rustup

      # =================================================================
      # Kubernetes (commented out)
      # =================================================================
      docker-compose
      kubectl
      krew # kubectl plugins
      kubie # fzf kubeconfig browser
      kind # k8s in docker
      kubent # check for deprecations
      prometheus # prometheus linter
      kubebuilder # generate controller
      kubernetes-helm # deploy applications

      # Core Unix utilities
      moreutils # Additional Unix utilities (sponge, vidir, etc)

      # Nix utilities
      optinix # Nix flake utilities
    ]
  );
}
