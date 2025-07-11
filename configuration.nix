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
  ];

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      download-buffer-size = 500000000; # 500 MB
      # Faster builds
      cores = 0;
      # Return more information when errors happen
      show-trace = true;
    };
    # Use the pinned nixpkgs version that is already used, when using `nix shell nixpkgs#package`
    registry.nixpkgs = {
      from = {
        id = "nixpkgs";
        type = "indirect";
      };
      flake = inputs.nixpkgs;
    };
  };

  security.sudo = {
    execWheelOnly = true; # For security
    package = pkgs.sudo.override { withInsults = true; };
    extraConfig = "Defaults insults";
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  users = {
    groups = {
      microbin = { };
      miniflux = { };
      samba = { };
      kavita = { };
      mqtt = { };
      git = { };
    };

    users = {
      zeev = {
        isNormalUser = true;
        description = "Zeev";
        shell = pkgs.zsh;
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
          "media"
          "samba"
        ];
        hashedPasswordFile = config.sops.secrets.zeev_password.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks 4rmcyt@gmail.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAokdbrMinZjhDnVLnrXOjNn9SvzsPdlP6P3T9hAtGG8 vk@Volodymyr-Kondratenko-Mac.local"
        ];
      };

      microbin = {
        isSystemUser = true;
        group = "microbin";
        extraGroups = [ "work" ];
      };
      miniflux = {
        isSystemUser = true;
        group = "miniflux";
        extraGroups = [ "work" ];
      };
      samba = {
        isSystemUser = true;
        group = "samba";
        extraGroups = [ "work" ];
      };
      kavita = {
        isSystemUser = true;
        group = "kavita";
        extraGroups = [ "media" ];
      };
      mqtt = {
        isSystemUser = true;
        group = "mqtt";
      };
      git = {
        isSystemUser = true;
        group = "git";
        home = "/var/lib/git-server";
        createHome = true;
        shell = "${pkgs.git}/bin/git-shell";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks 4rmcyt@gmail.com"
        ];
      };
      nextcloud.extraGroups = [ "work" ];
      radicale.extraGroups = [ "work" ];
      paperless.extraGroups = [ "work" ];
    };
  };

  environment.systemPackages = with pkgs; [
    zsh
    direnv
    pass
    neovim
    git
    vim
    wget
    curl
    jq
    coreutils
    gawk
    gnugrep
    iproute2
    mc
    htop
    btop
    lsof
    age
    sops
    ssh-to-age
    openssh
    wireguard-tools
    apacheHttpd
    zsh-powerlevel10k
    meslo-lgs-nf
    yamllint
    nix-index

    zip
    unar
    unzip
    p7zip
    calibre

    # Terminal programs
    iotop
    tuptime # Uptime doesn't work lol
    git
    smartmontools
    fzf
    ffmpeg
    nmap
    trash-cli
    wget

  ];

    systemd.tmpfiles.rules = [
    "d /home/zeev/media 0770 zeev media -",
    "d /home/zeev/downloads 0770 zeev media -",
    "d /home/zeev/media/.state 0770 zeev media -",
    "d /home/zeev/media/.state/nixarr 0770 zeev media -",
    
    # This rule gives the 'media' group permission to enter /home/zeev
    "A /home/zeev - - - - d:g:media:X,g:media:X",
    # This rule gives the 'media' group full permissions for your media folder
    "A /home/zeev/media - - - - d:g:media:rwx,g:media:rwx"
  ];


  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        PubkeyAuthentication = true;
        X11Forwarding = false;
        MaxAuthTries = 3;
        LoginGraceTime = "30s";
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
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
    secrets = {
      zeev_password.neededForUsers = true;
      nextcloud_admin_password = { };
      microbin_admin_password = { };
      tailscale_auth_key = { };
      telegram_bot_token = { };
      telegram_chat_id = { };
    };
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
    users = {
      zeev = import ./home.nix;
    };
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}
