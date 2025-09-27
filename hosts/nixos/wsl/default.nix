{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    inputs.vscode-server.nixosModules.default
    ../../../modules/users/zeev
    ../../../modules/base
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
      docker-desktop.enable = false;
    };
  };

  # Allow loading NVIDIA driver
  boot.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [ pkgs.linuxPackages.nvidia_x11 ];

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
      substituters = [
        "https://nix-community.cachix.org"
        "https://4rmcyt.cachix.org"
        "https://numtide.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "4rmcyt.cachix.org-1:IzZEPOd8aKavFKw3BuUBAI/T93XUUWoS/n2M+LG65/0="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "zeev" ];
      download-buffer-size = 1073741824;
      warn-dirty = false;
    };
  };

  networking.firewall.allowedTCPPorts = [
    4242 # Kavita
  ];

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
    nixos-rebuild
    lan-mouse
    sops
    cmake-format
    nodePackages.prettier
    rustfmt
    nixfmt-rfc-style
    deadnix
    statix
    yamlfmt
    toml-sort
    shfmt
    just
    dockfmt
    alejandra
    nix-diff
  ];

  time.timeZone = "America/Edmonton";

  environment.etc."ld.so.conf.d/wsl-nvidia.conf".text = ''
    /usr/lib/wsl/lib
  '';
  environment.sessionVariables = {
    LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
  };
  environment.variables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    CUDA_ROOT = "${pkgs.cudatoolkit}";
    EXTRA_LDFLAGS = "-L/usr/lib/wsl/lib -L${pkgs.cudatoolkit}/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I${pkgs.cudatoolkit}/include";
    NVIDIA_DRIVER_PATH = "/usr/lib/wsl/lib";
  };

  networking = {
    hostName = "nixos-wsl";
    networkmanager.enable = false;
    useNetworkd = false;
    useDHCP = false;
    dhcpcd.enable = false;
    wireless.enable = false;
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
