{
  pkgs,
  inputs,
  ...
}: {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    # External modules
    inputs.nixos-wsl.nixosModules.wsl
    inputs.vscode-server.nixosModules.default

    # System base
    ../../../modules/base
    ../../../modules/options

    # User configuration
    ../../../modules/users/zeev
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. Time Configuration
  # =================================================================
  time.timeZone = "America/Edmonton";

  # =================================================================
  # 5. Boot Configuration
  # =================================================================
  boot = {
    kernelModules = ["nvidia"];
    extraModulePackages = [pkgs.linuxPackages.nvidia_x11];
  };

  # =================================================================
  # 6. Hardware Configuration
  # =================================================================
  hardware = {
    # Graphics
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # NVIDIA CUDA Support for WSL
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = false;
      package = pkgs.linuxPackages.nvidia_x11;
    };
  };

  # =================================================================
  # 7. Users & Groups
  # =================================================================
  users = {
    users.git = {
      isSystemUser = true;
      description = "Git user";
    };
    groups.git = {};
  };

  # =================================================================
  # 8. Nix Configuration
  # =================================================================
  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config = {
      cudaSupport = true;
    };
  };

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      cores = 0;

      experimental-features = [
        "flakes"
        "nix-command"
      ];

      auto-optimise-store = true;
      warn-dirty = false;
      max-jobs = "auto"; # Auto-detect job count
      keep-going = true; # Continue building other derivations on failure

      # Network optimization for faster downloads
      max-substitution-jobs = 4; # Parallel downloads
      http-connections = 25; # More HTTP connections
      connect-timeout = 5; # Faster timeout

      # Store optimization for better performance
      keep-outputs = true; # Keep build dependencies for faster rebuilds
      keep-derivations = true; # Keep derivations for faster evaluation

      # Disk space management
      min-free = 5368709120; # 5GB - trigger GC when less than 5GB free
      max-free = 10737418240; # 10GB - stop GC when 10GB free

      # Build performance improvements
      builders-use-substitutes = true; # Allow builders to use substitutes
      require-sigs = true; # Security: require signatures
      
      substituters = [
        "https://cache.nixos.org"
        "https://4rmcyt-wsl.cachix.org"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://cache.flox.dev"
        "https://cuda-maintainers.cachix.org"
      ];
      system-features = [
        "benchmark"
        "big-parallel"
        "gccarch-znver3"
        "kvm"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "4rmcyt-wsl.cachix.org-1:6Z2J6lPY35L3qxBgEYzyN0Q3Y6LCJhtz/YeY4VQ29BU="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  # =================================================================
  # 9. Secrets Management
  # =================================================================
  sops = {
    age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
    defaultSopsFormat = "yaml";
  };

  # =================================================================
  # 10. Networking
  # =================================================================
  networking = {
    hostName = "wsl";
    networkmanager.enable = false;
    useNetworkd = false;
    useDHCP = false;
    dhcpcd.enable = false;
    wireless.enable = false;
    interfaces = {};
    firewall.allowedTCPPorts = [
      4242 # Kavita
    ];
  };

  # =================================================================
  # 11. Systemd Configuration
  # =================================================================
  systemd.network.enable = false;

  # =================================================================
  # 12. Services
  # =================================================================
  services = {
    # SSH configuration
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Development services
    vscode-server.enable = true;

    # System services
    resolved.enable = false;
    xserver.videoDrivers = ["nvidia"];
  };

  # =================================================================
  # 13. Programs
  # =================================================================

  programs = {
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/zeev/src/nix-config";
    };
    zsh.enable = true;
  };

  # =================================================================
  # 14. WSL Configuration
  # =================================================================
  wsl = {
    enable = true;
    defaultUser = "zeev";
    startMenuLaunchers = true;
    useWindowsDriver = true;
    wslConf = {
      automount.root = "/mnt";
      interop.appendWindowsPath = false;
      network.generateHosts = true;
      network.generateResolvConf = true;
    };
  };

  # =================================================================
  # 15. Environment Configuration
  # =================================================================
  environment = {
    # CUDA and NVIDIA environment variables
    variables = {
      CUDA_PATH = "${pkgs.cudatoolkit}";
      CUDA_ROOT = "${pkgs.cudatoolkit}";
      EXTRA_LDFLAGS = "-L/usr/lib/wsl/lib -L${pkgs.cudatoolkit}/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
      EXTRA_CCFLAGS = "-I${pkgs.cudatoolkit}/include";
      NVIDIA_DRIVER_PATH = "/usr/lib/wsl/lib";
    };

    sessionVariables = {
      LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
    };

    # NVIDIA library configuration
    etc."ld.so.conf.d/wsl-nvidia.conf".text = ''
      /usr/lib/wsl/lib
    '';

    # System packages
    systemPackages = with pkgs; [
      # Core utilities
      coreutils
      curl
      findutils
      gawk
      git
      git-crypt
      gnugrep
      gnused
      mc
      rsync
      unzip
      util-linux
      vim
      wget
      zip

      # CUDA and graphics
      cudatoolkit
      libGL
      libGLU
      linuxPackages.nvidia_x11

      # System tools
      lan-mouse
      nixos-rebuild
      sops

      # Development & formatting tools
      alejandra
      cmake-format
      deadnix
      dockfmt
      just
      nix-diff
      nixfmt-rfc-style
      nodePackages.prettier
      rustfmt
      shfmt
      statix
      toml-sort
      yamlfmt
    ];
  };

  environment.shells = with pkgs; [zsh];
  home-manager.backupFileExtension = "backup";
}
