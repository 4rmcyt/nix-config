{
  config,
  pkgs,
  ...
}:
{
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    ../../../modules/base
    ../../../modules/options
    ../../../modules/networking/ssh
    ../../../modules/networking/avahi
    ../../../modules/users/zeev
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. Secrets Management
  # =================================================================
  sops = {
    age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
    defaultSopsFormat = "yaml";
    secrets = {
      git_access_token = {
        sopsFile = ../../../secrets/common.yaml;
        key = "git_access_token";
      };
    };
  };

  # =================================================================
  # 3.5. Systemd Services - Nix Daemon GitHub Token
  # =================================================================
  # Note: The git_access_token secret should contain: NIX_CONFIG="access-tokens = github.com=<token>"
  systemd.services.nix-daemon.serviceConfig.Environment = [
    "NIX_CONFIG=access-tokens = github.com=$(cat ${config.sops.secrets.git_access_token.path})"
  ];

  # =================================================================
  # 4. Boot Configuration
  # =================================================================
  boot = {
    kernelModules = [ "nvidia" ];
    extraModulePackages = [ pkgs.linuxPackages.nvidia_x11 ];

    # System control parameters for WSL
    kernel.sysctl = {
      # Kernel optimizations
      "kernel.nmi_watchdog" = 0;

      # VM/Memory optimizations (WSL typically has dynamic RAM)
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;

      # Network optimizations
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.tcp_fastopen" = 3;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  # =================================================================
  # 5. Nixpkgs Configuration
  # =================================================================
  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config = {
      cudaSupport = true;
    };
  };

  # =================================================================
  # 6. Nix Configuration
  # =================================================================

  nix.settings = {
    cores = 4;

    experimental-features = [
      "flakes"
      "nix-command"
      "auto-allocate-uids"
    ];

    auto-optimise-store = true;
    warn-dirty = false;
    max-jobs = "auto"; # Auto-detect job count
    keep-going = true; # Continue building other derivations on failure

    # Network optimization for faster downloads
    max-substitution-jobs = 16; # Parallel downloads
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

    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # =================================================================
  # 7. Environment
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
      # GPG Agent for SSH (uses gpg-agent socket)
      SSH_AUTH_SOCK = "/run/user/$UID/gnupg/S.gpg-agent.ssh";
      LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
    };

    # NVIDIA library configuration
    etc."ld.so.conf.d/wsl-nvidia.conf".text = ''
      /usr/lib/wsl/lib
    '';

    shells = with pkgs; [ zsh ];

    # System packages
    systemPackages = with pkgs; [
      # Core utilities (WSL-specific)
      rsync
      util-linux
      zip

      # CUDA and graphics
      cudatoolkit
      libGL
      libGLU
      linuxPackages.nvidia_x11

      # System tools
      lan-mouse
      nixos-rebuild
    ];
  };

  # =================================================================
  # 8. Hardware
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
  # 9. Home Manager
  # =================================================================
  # backupFileExtension is set in commonHomeManagerNixosConfig with unique timestamp

  # =================================================================
  # 10. Networking
  # =================================================================
  networking = {
    hostName = "wsl";
    networkmanager.enable = false;
    useNetworkd = false;
    useDHCP = false;
    dhcpcd.enable = false;
    interfaces = { };
    firewall.allowedTCPPorts = [
      4242 # Kavita
    ];
  };

  # =================================================================
  # 11. Programs
  # =================================================================
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-tty;
    };

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
    xserver.videoDrivers = [ "nvidia" ];
  };

  # =================================================================
  # 13. Time Configuration
  # =================================================================
  time.timeZone = "America/Edmonton";

  # =================================================================
  # 14. Users & Groups
  # =================================================================
  users = {
    users.git = {
      isSystemUser = true;
      description = "Git user";
    };
    users.zeev.shell = pkgs.zsh;
    groups.git = { };
  };

  # =================================================================
  # 15. Systemd Configuration
  # =================================================================
  systemd.network.enable = false;

  # =================================================================
  # 16. WSL Configuration
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
}
