{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./users
    ./networking
    ./modules/base
    ./modules/sops
  ];

  

  security.sudo.execWheelOnly = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  environment.systemPackages = with pkgs; [
    zsh git neovim direnv pass vim wget curl jq coreutils gawk gnugrep
    iproute2 mc htop btop lsof age sops ssh-to-age openssh wireguard-tools dive
    apacheHttpd meslo-lgs-nf yamllint nix-index iotop cachix
    tuptime smartmontools fzf ffmpeg nmap trash-cli zip unar unzip p7zip
    go nextdns nixfmt-rfc-style nil deploy-rs just nixpkgs-fmt tree git-crypt python3Full
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

    ollama = {
      enable = false;
      loadModels = [
        "phi3:mini" # Specify the model you want to pre-load
      ];
    };



    nextdns = {
      enable = true;
      arguments = [ "-profile" "nextdns0" "-cache-size" "10MB" "--report-client-info" ];
    };
    vscode-server.enable = true;
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh.enable = true;
    nix-ld.dev.enable = false;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.zeev = import ./home-manager;
  };
  
  
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}
