{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  users = {
    groups = {
      media = {};
      microbin = {};
      miniflux = {};
      samba = {};
      kavita = {};
      transmission = {};
      git = {};
    };
    users = {
      zeev = {
        isNormalUser = true;
        description = "Zeev";
        shell = pkgs.zsh;
        extraGroups = [ "networkmanager" "wheel" "docker" "media" "samba" ];
        hashedPasswordFile = config.sops.secrets.zeev_password.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks 4rmcyt@gmail.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAokdbrMinZjhDnVLnrXOjNn9SvzsPdlP6P3T9hAtGG8 vk@Volodymyr-Kondratenko-Mac.local"
        ];
      };
      microbin = { isSystemUser = true; group = "microbin"; extraGroups = [ "media" ]; };
      miniflux = { isSystemUser = true; group = "miniflux"; extraGroups = [ "media" ]; };
      samba = { isSystemUser = true; group = "samba"; extraGroups = [ "media" ]; };
      kavita = { isSystemUser = true; group = "kavita"; extraGroups = [ "media" ]; };
      git = {
        isSystemUser = true;
        group = "git";
        home = "/var/lib/git-server";
        createHome = true;
        shell = "${pkgs.git}/bin/git-shell";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks 4rmcyt@gmail.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAokdbrMinZjhDnVLnrXOjNn9SvzsPdlP6P3T9hAtGG8 vk@Volodymyr-Kondratenko-Mac.local"
        ];
      };
      nextcloud.extraGroups = [ "media" ];
      radicale.extraGroups = [ "media" ];
      paperless.extraGroups = [ "media" ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      zeev = import ./home.nix;
    };
  };

  environment.systemPackages = with pkgs; [
    zsh
    git vim wget curl jq coreutils gawk gnugrep iproute2 neovim mc
    htop btop lsof
    age sops ssh-to-age openssh
    wireguard-tools apacheHttpd
    zsh-powerlevel10k meslo-lgs-nf
  ];

  systemd.tmpfiles.rules = [
    "d /home/zeev 0770 zeev media -"
    "d /home/zeev/media 0770 zeev media -"
    "d /home/zeev/media/audiobooks 0770 zeev media -"
    "d /home/zeev/media/podcasts 0770 zeev media -"
    "d /home/zeev/media/movies 0770 zeev media -"
    "d /home/zeev/media/series 0770 zeev media -"
    "d /home/zeev/media/music 0770 zeev media -"
    "d /home/zeev/media/other 0770 zeev media -"
    "d /home/zeev/media/library 0775 zeev media -"
    "d /home/zeev/media/library/books 0775 zeev media -"
    "d /home/zeev/media/library/comics 0775 zeev media -"
    "d /home/zeev/media/library/manga 0775 zeev media -"
    "d /home/zeev/Downloads 0770 zeev media -"
    "d /home/zeev/Downloads/incomplete 0770 zeev media -"
    "d /home/zeev/Downloads/torrents 0770 zeev media -"
  ];

  programs = {
    neovim.defaultEditor = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autocd = true;
      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch --flake .#homeserver";
      };
      plugins = [
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
        }
        {
          name = "zsh-completions";
          src = pkgs.zsh-completions;
        }
        {
          name = "zsh-history-substring-search";
          src = pkgs.zsh-history-substring-search;
        }
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
        }
        {
          name = "you-should-use";
          src = pkgs.you-should-use;
        }
        {
          name = "do-you-even-nix";
          src = pkgs.zsh-do-you-even-nix;
        }
      ];
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "direnv" "pass" "nix" "nix-shell" ];
        theme = "powerlevel10k";
      };
      powerlevel10k = {
        enable = true;
        enableTransientPrompt = true;
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        PubkeyAuthentication = true;
        X11Forwarding = false;
        MaxAuthTries = 3;
        LoginGraceTime = "30s";
      };
    };
    vscode-server.enable = true;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
    secrets = {
      zeev_password.neededForUsers = true;
      nextcloud_admin_password = {};
      microbin_admin_password = {};
      tailscale_auth_key = {};
      pia_credentials = {};
      telegram_bot_token = {};
      telegram_chat_id = {};
    };
  };

  system.stateVersion = "25.05";
}

