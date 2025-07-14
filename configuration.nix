{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  allKeys = import ./secrets.nix;
in  
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
      download-buffer-size = 500000000;
      cores = 0;
      show-trace = true;
    };
    registry.nixpkgs = {
      from = { id = "nixpkgs"; type = "indirect"; };
      flake = inputs.nixpkgs;
    };
  };

  security.sudo.execWheelOnly = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  users = {
    groups.media = {};
    groups.samba = {};
    groups.git = {};
    users = {
      zeev = {
        isNormalUser = true;
        description = "Zeev";
        shell = pkgs.zsh;
        extraGroups = [ "networkmanager" "wheel" "docker" "media" "samba" ];
        hashedPasswordFile = config.sops.secrets.zeev_password.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks redacted@example.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAokdbrMinZjhDnVLnrXOjNn9SvzsPdlP6P3T9hAtGG8 vk@Volodymyr-Kondratenko-Mac.local"
        ];
      };
      git = {
        isSystemUser = true;
        group = "git";
        home = "/var/lib/git-server";
        createHome = true;
        shell = "${pkgs.git}/bin/git-shell";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks redacted@example.com"
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    zsh git neovim direnv pass vim wget curl jq coreutils gawk gnugrep
    iproute2 mc htop btop lsof age sops ssh-to-age openssh wireguard-tools
    apacheHttpd zsh-powerlevel10k meslo-lgs-nf yamllint nix-index iotop
    tuptime smartmontools fzf ffmpeg nmap trash-cli zip unar unzip p7zip
    calibre
  ];

  services = {
    openssh = {
      enable = true;
      hostKeys = [
        { type = "ed25519"; path = config.sops.secrets.ssh_host_ed25519_key.path; }
        { type = "rsa"; bits = 4096; path = config.sops.secrets.ssh_host_rsa_key.path; }
      ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
      extraConfig = ''
        Match user git
          AllowTcpForwarding no
          AllowAgentForwarding no
          PasswordAuthentication no
          PermitTTY no
          X11Forwarding no
      '';
    };
    vscode-server.enable = true;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/etc/sops/age.key";
    secrets = {
      zeev_password.neededForUsers = true;
      ssh_host_ed25519_key = { owner = "root"; group = "root"; mode = "0600"; };
      ssh_host_rsa_key = { owner = "root"; group = "root"; mode = "0600"; };
      nextcloud_admin_password = {};
      microbin_admin_password = {};
      tailscale_auth_key = {};
      telegram_bot_token = {};
      telegram_chat_id = {};
    };
  };

  programs = {
    gnupg.agent = { enable = true; enableSSHSupport = true; };
    zsh.enable = true;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.zeev = import ./home.nix;
  };
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}