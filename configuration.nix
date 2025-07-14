{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Import your keys file here at the top
  allKeys = import ./keys.nix;
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
    groups = {
      media = {};
      samba = {};
      git = {};
      homepage-dashboard = {};
    };
    users = {
      zeev = {
        isNormalUser = true;
        description = "Zeev";
        shell = pkgs.zsh;
        extraGroups = [ "networkmanager" "wheel" "docker" "media" "samba" ];
        hashedPasswordFile = config.sops.secrets.zeev_password.path;
        openssh.authorizedKeys.keys = allKeys.server-keys;
      };
      git = {
        isSystemUser = true;
        group = "git";
        home = "/var/lib/git-server";
        createHome = true;
        shell = "${pkgs.git}/bin/git-shell";
        openssh.authorizedKeys.keys = allKeys.user-keys;
      };
      homepage-dashboard = {
        isSystemUser = true;
        group = "homepage-dashboard";
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