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
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
      download-buffer-size = 500000000;
      cores = 0;
      show-trace = true;
    };
    registry.nixpkgs.from = {
      id = "nixpkgs";
      type = "indirect";
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  security.sudo = {
    execWheelOnly = true;
    package = pkgs.sudo.override { withInsults = true; };
    extraConfig = "Defaults insults";
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  users = {
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
    };
  };

  environment.systemPackages = with pkgs; [
    # Shell
    zsh zsh-powerlevel10k meslo-lgs-nf
    # Dev
    git neovim direnv pass
    # Tools
    vim wget curl jq coreutils gawk gnugrep iproute2 mc htop btop lsof age sops ssh-to-age openssh wireguard-tools apacheHttpd yamllint nix-index iotop tuptime smartmontools fzf ffmpeg nmap trash-cli
    # Archives
    zip unar unzip p7zip
    # Misc
    calibre
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
      nextcloud_admin_password = {};
      microbin_admin_password = {};
      tailscale_auth_key = {};
      telegram_bot_token = {};
      telegram_chat_id = {};
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


  environment.etc."nixos/scripts/add-trackers.sh" = {
  # The mode "0755" makes the script executable
  mode = "0755";
  # The text of the script
  text = ''
    #!/binis/sh

    # Use direct paths to programs for reliability in NixOS
    TRANSMISSION_REMOTE="${pkgs.transmission}/bin/transmission-remote"
    WGET="${pkgs.wget}/bin/wget"
    SED="${pkgs.gnused}/bin/sed"
    WC="${pkgs.coreutils}/bin/wc"
    CAT="${pkgs.coreutils}/bin/cat"

    TRACKERLIST="/tmp/trackers.list"

    # Clean up the temp file on exit
    trap "rm -f $TRACKERLIST" EXIT

    # Get tracker lists
    $WGET https://newtrackon.com/api/stable -O "$TRACKERLIST"
    $WGET https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt -O - >> "$TRACKERLIST"

    # Process the list
    $SED -i '/^$/d' "$TRACKERLIST"
    echo "[+] Got $($WC -l < "$TRACKERLIST") trackers"

    # Add trackers to all torrents
    while IFS= read -r TRACKER; do
      "$TRANSMISSION_REMOTE" -t all -td "$TRACKER"
    done < "$TRACKERLIST"
  '';
};
}