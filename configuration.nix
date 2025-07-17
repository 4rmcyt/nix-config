{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # The 'let' block has been removed from this file.
  imports = [
    ./users
    ./networking
    ./modules/base
    ./modules/sops
  ];

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
      cores = 0;
      show-trace = true;
      download-buffer-size = 524288000; # 500 MiB
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

  environment.systemPackages = with pkgs; [
    zsh git neovim direnv pass vim wget curl jq coreutils gawk gnugrep
    iproute2 mc htop btop lsof age sops ssh-to-age openssh wireguard-tools
    apacheHttpd zsh-powerlevel10k meslo-lgs-nf yamllint nix-index iotop
    tuptime smartmontools fzf ffmpeg nmap trash-cli zip unar unzip p7zip
    calibre go
  ];

  services = {
    openssh = {
      enable = true;
      hostKeys = [
        {
          type = "ed25519";
          path = config.sops.secrets.ssh_host_ed25519_key.path;
        }
        {
          type = "rsa";
          bits = 4096;
          path = config.sops.secrets.ssh_host_rsa_key.path;
        }
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
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh.enable = true;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.zeev = import ./home-manager;
  };
  
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}
