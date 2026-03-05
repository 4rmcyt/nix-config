# WSL host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.wsl.module = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      nixosBase

      # Existing NixOS modules
      ../../../modules/base
      ../../../modules/options
      ../../../modules/networking/ssh
      ../../../modules/networking/avahi
      ../../../modules/users/zeev

      # WSL-specific input
      inputs.nixos-wsl.nixosModules.wsl
    ];

    # System
    nixpkgs.config.cudaSupport = true;
    time.timeZone = owner.timezone;

    # Sops secrets
    sops = {
      age.keyFile = "/home/${owner.username}/.config/sops/age/keys.txt";
      defaultSopsFormat = "yaml";
    };

    # Nix settings (host-specific)
    nix.settings = {
      cores = 4;
      experimental-features = [
        "flakes"
        "nix-command"
        "auto-allocate-uids"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      max-jobs = "auto";
      keep-going = true;
      max-substitution-jobs = 16;
      http-connections = 25;
      connect-timeout = 5;
      keep-outputs = true;
      keep-derivations = true;
      min-free = 5368709120;
      max-free = 10737418240;
      builders-use-substitutes = true;
      require-sigs = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    # Boot
    boot = {
      kernelModules = ["nvidia"];
      extraModulePackages = [pkgs.linuxPackages.nvidia_x11];
      kernel.sysctl = {
        "kernel.nmi_watchdog" = 0;
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 50;
        "vm.dirty_ratio" = 15;
        "vm.dirty_background_ratio" = 5;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 65536 16777216";
        "net.ipv4.tcp_fastopen" = 3;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    };

    # Environment
    environment = {
      variables = {
        CUDA_PATH = "${pkgs.cudatoolkit}";
        CUDA_ROOT = "${pkgs.cudatoolkit}";
        EXTRA_LDFLAGS = "-L/usr/lib/wsl/lib -L${pkgs.cudatoolkit}/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
        EXTRA_CCFLAGS = "-I${pkgs.cudatoolkit}/include";
        NVIDIA_DRIVER_PATH = "/usr/lib/wsl/lib";
      };
      sessionVariables = {
        SSH_AUTH_SOCK = "/run/user/$UID/gnupg/S.gpg-agent.ssh";
        LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
      };
      etc."ld.so.conf.d/wsl-nvidia.conf".text = ''
        /usr/lib/wsl/lib
      '';
      shells = with pkgs; [zsh];
      systemPackages = with pkgs; [
        rsync
        util-linux
        zip
        cudatoolkit
        libGL
        libGLU
        linuxPackages.nvidia_x11
        lan-mouse
        nixos-rebuild
      ];
    };

    # Hardware
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = false;
        package = pkgs.linuxPackages.nvidia_x11;
      };
    };

    # Networking
    networking = {
      hostName = "wsl";
      networkmanager.enable = false;
      useNetworkd = false;
      useDHCP = false;
      dhcpcd.enable = false;
      interfaces = {};
      firewall.allowedTCPPorts = [4242];
    };
    systemd.network.enable = false;

    # Programs
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
        flake = "/home/${owner.username}/src/nix-config";
      };
      zsh.enable = true;
    };

    # Services
    services = {
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      vscode-server.enable = true;
      resolved.enable = false;
      xserver.videoDrivers = ["nvidia"];
      timesyncd.enable = lib.mkForce false;
    };

    # Users
    users = {
      users.git = {
        isSystemUser = true;
        description = "Git user";
        group = "git";
      };
      users.${owner.username}.shell = pkgs.zsh;
      groups.git = {};
    };

    # WSL
    wsl = {
      enable = true;
      defaultUser = owner.username;
      startMenuLaunchers = true;
      useWindowsDriver = true;
      wslConf = {
        automount.root = "/mnt";
        interop.appendWindowsPath = false;
        network.generateHosts = true;
        network.generateResolvConf = true;
      };
    };

    # Host-specific HM imports and config
    home-manager.users.${owner.username} = {
      imports = [
        ../../../modules/TUI/common
        ../../../modules/TUI/zsh
        ../../../modules/TUI/atuin
        ../../../modules/GUI/terminal/wezterm
      ];

      home.packages = with pkgs; [
        deploy-rs
        go
        nix-inspect
        nixfmt-tree
        pyenv
        meslo-lgs-nf
        nerd-fonts.hack
        cowsay
        fortune
        firefox
        pass
        nextdns
        pwgen
        sudo
        tmux
        tuptime
        trash-cli
        tree
        yamllint
        zip
        wslu
      ];

      programs.zsh.enable = true;
      programs.zsh.profileExtra = ''
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
      '';

      xdg = {
        enable = true;
        mimeApps.enable = true;
      };
    };
  };
}
