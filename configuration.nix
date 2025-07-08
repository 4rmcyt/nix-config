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

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      X11Forwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
    openFirewall = true;
  };

  services.pia-vpn = {
    enable = true;
    environmentFile = config.sops.secrets.pia_credentials.path;
    certificateFile = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/pia-foss/manual-connections/master/ca.rsa.4096.crt";
      sha256 = "sha256-Mumx0UM+qXYU8qFMbjWOP1fAVwzJ9rLugSaZumlsZqs=";
    };
    maxLatency = 18.0;
    portForward.enable = true;
  };

  systemd.services.transmission-vpn-handler = {
    description = "Prepare Transmission config after PIA port is forwarded";

    # This dependency remains correct.
    after = [ "pia-vpn-portforward.service" ];

    # --- KEY CHANGE ---
    # This tells systemd not to include this service in the initial boot-up
    # transaction. This prevents the 'nixos-rebuild switch' from getting stuck.
    wantedBy = lib.mkForce [ ];

    # The script is perfect and needs no changes.
    script = ''
      #!${pkgs.runtimeShell}
      # ... (script content is unchanged) ...
      while [ ! -f /run/pia-vpn/port ]; do sleep 1; done
      PORT=$(cat /run/pia-vpn/port)
      VPN_IP=""
      while [ -z "$VPN_IP" ]; do
        VPN_IP=$(${pkgs.iproute2}/bin/ip -4 addr show wg0 | ${pkgs.gnugrep}/bin/grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        sleep 1
      done
      echo "Handler: Found Port $PORT and IP $VPN_IP. Preparing config." | ${pkgs.systemd}/bin/systemd-cat -t transmission-hook
      SETTINGS_FILE="/var/lib/transmission/.config/transmission-daemon/settings.json"
      ${pkgs.jq}/bin/jq \
        --arg ip "$VPN_IP" --argjson port "$PORT" \
        '."bind-address-ipv4" = $ip | ."peer-port" = $port' \
        "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # The Transmission service now requires and starts the handler.
  systemd.services.transmission = {
    requires = [ "transmission-vpn-handler.service" ];
    after = [ "transmission-vpn-handler.service" ];

    # --- KEY CHANGE ---
    # This tells systemd that whenever the main services are started
    # (like on boot), this service should also be started.
    wantedBy = [ "multi-user.target" ];

    serviceConfig.BindToDevice = "wg0";
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    openFirewall = true;
    openPeerPorts = true;
    openRPCPort = true;
    settings = {
      "download-dir" = "/home/zeev/Downloads";
      "rpc-whitelist" = "127.0.0.1,192.168.1.*,100.64.0.*,localhost,transmission.labhome.work";
      "rpc-host-whitelist-enabled" = "false";
      "rpc-whitelist-enabled" = "false";
      "incomplete-dir" = "/home/zeev/Downloads/incomplete";
      "incomplete-dir-enabled" = true;
      "watch-dir" = "/home/zeev/Downloads/torrents";
      "dht-enabled" = "true";
      "script-torrent-added-enabled" = "true";
      "script-torrent-added-filename" = "/etc/nixos/scripts/add-trackers.sh";
      "blocklist-enabled" = true;
      "blocklist-url" = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
    };
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";

  sops.secrets.zeev_password = {
    neededForUsers = true;
  };
  sops.secrets.nextcloud_admin_password = { };
  sops.secrets.microbin_admin_password = { };
  sops.secrets.tailscale_auth_key = { };
  sops.secrets.pia_credentials = { };
  sops.secrets.telegram_bot_token = { };
  sops.secrets.telegram_chat_id = { };

  users.groups = {
    media = { };
    microbin = { };
    miniflux = { };
    samba = { };
    kavita = { };
  };

  users.users = {
    # Main user
    zeev = {
      isNormalUser = true;
      description = "Zeev";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "media"
        "samba"
      ];
      hashedPasswordFile = config.sops.secrets.zeev_password.path;
      shell = pkgs.bash;
    };

    # System users for services
    microbin = {
      isSystemUser = true;
      group = "microbin";
      extraGroups = [ "media" ];
    };

    miniflux = {
      isSystemUser = true;
      group = "miniflux";
      extraGroups = [ "media" ];
    };

    samba = {
      isSystemUser = true;
      group = "samba";
      extraGroups = [ "media" ];
    };

    transmission = {
      isSystemUser = true;
      group = "transmission";
      extraGroups = [
        "media"
        "users"
        "pia-vpn"
      ];
    };

    kavita = {
      isSystemUser = true;
      group = "kavita";
      extraGroups = [ "media" ];
    };
  };

  # Add existing service users to media group where needed
  users.users.nextcloud.extraGroups = [ "media" ];
  users.users.radicale.extraGroups = [ "media" ];
  users.users.paperless.extraGroups = [ "media" ];

  # CENTRALIZED: Media directory structure (moved from individual services)
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

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    jq
    age
    sops
    openssh
    neovim
    mc
    wireguard-tools
    iproute2
    apacheHttpd
    htop
    btop
    lsof
  ];

  # Enable Home Manager
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      zeev = import ./home.nix;
    };
  };

  # Enable VSCode server
  services.vscode-server.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
