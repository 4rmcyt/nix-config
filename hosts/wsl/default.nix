{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    inputs.vscode-server.nixosModules.default
    ../../modules/users/zeev
    ../../modules/base
  ];

  sops = {
    age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
    defaultSopsFormat = "yaml";
  };

  users.users.git = {
    isSystemUser = true;
    description = "Git user";
  };
  users.groups.git = { };

  # VSCode Server Configuration
  services.vscode-server.enable = true;

  # WSL Configuration
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

  # Allow loading NVIDIA driver
  boot.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [ pkgs.linuxPackages.nvidia_x11 ];

  home-manager.backupFileExtension = "backup";
  # System Configuration
  system.stateVersion = "25.05";

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  # NVIDIA CUDA Support for WSL
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = false;
    package = pkgs.linuxPackages.nvidia_x11;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "zeev" ];
      download-buffer-size = 1073741824; 
      warn-dirty = false;
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    rsync
    unzip
    zip
    coreutils
    gnugrep
    gawk
    gnused
    findutils
    util-linux
    mc
    cudatoolkit
    linuxPackages.nvidia_x11
    libGL
    libGLU
  ];

   time.timeZone = "America/Edmonton";

  environment.variables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    CUDA_ROOT = "${pkgs.cudatoolkit}";
    LD_LIBRARY_PATH = "/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
  };

  networking = {
    hostName = "nixos-wsl";
    networkmanager.enable = false;
    useNetworkd = false;
    useDHCP = false;
    dhcpcd.enable = false;
    wireless.enable = false;
    # Don't manage interfaces
    interfaces = { };
  };

  systemd.network.enable = false;
  services.resolved.enable = false;

  # Enable services
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
}
