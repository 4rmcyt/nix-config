{
  pkgs,
  lib,
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

  # System Configuration
  system.stateVersion = "25.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nix Configuration
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "zeev" ];
      warn-dirty = false;
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Essential packages for WSL
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    rsync
    unzip
    zip
    wslu
  ];

  networking = {
    hostName = "nixos-wsl";
    networkmanager.enable = false;
    useNetworkd = false;
    useDHCP = false;
    dhcpcd.enable = false;
    wireless.enable = false;
    # Don't manage interfaces
    interfaces = {};
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
}