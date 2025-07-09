{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
let
  piaInterface = config.services.pia-vpn.interface;
in
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
    portForward = {
      enable = true;
      script = ''
        ${pkgs.transmission_4}/bin/transmission-remote --port $port || true
      '';
    };
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    # Key change here: use the piaInterface variable for rpc-bind-address
    settings = {
      "download-dir" = "/home/zeev/Downloads";
      "rpc-bind-address" = "0.0.0.0"; # Keep this as 0.0.0.0 for RPC to be accessible
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
      # You can also set the 'bind-address-ipv4' here if you want to explicitly bind torrent traffic
      # to the VPN IP, though RPC bind address is often sufficient for most use cases.
      "bind-address-ipv4" = "$(${pkgs.iproute2}/bin/ip -j addr show dev ${piaInterface} | ${pkgs.jq}/bin/jq -r '.[0].addr_info | map(select(.family == "inet"))[0].local')";
      # NOTE: This dynamic binding for torrent traffic might still have timing issues.
      # A better approach is often to use network namespaces or stricter firewall rules
      # to ensure all traffic goes through the VPN, rather than relying on application binding alone.
    };
  };

  # Remove or comment out this entire block
  systemd.services.transmission = {
    after = [ "pia-vpn.service" ];
    bindsTo = [ "pia-vpn.service" ];
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    # Use ExecStartPre to inject the dynamic IP into the settings file
    serviceConfig.ExecStartPre = ''
      set -euo pipefail
      # Ensure the config directory exists
      mkdir -p "${config.services.transmission.home}/.config/transmission-daemon"
      CONFIG_FILE="${config.services.transmission.home}/.config/transmission-daemon/settings.json"

      # Get the PIA interface IP
      IP=$(${pkgs.iproute2}/bin/ip -j addr show dev ${piaInterface} | ${pkgs.jq}/bin/jq -r '.[0].addr_info | map(select(.family == "inet"))[0].local')

      # Check if IP is empty or null (e.g., if VPN is not fully up yet)
      if [ -z "$IP" ] || [ "$IP" = "null" ]; then
        echo "Error: Could not determine IP address for ${piaInterface}. Aborting Transmission startup." >&2
        exit 1
      fi

      # Use jq to update the settings.json with the dynamic IP
      # If settings.json doesn't exist or is empty, jq will create it.
      # If 'bind-address-ipv4' exists, it will be updated.
      ${pkgs.jq}/bin/jq --arg ip "$IP" '. + {"bind-address-ipv4": $ip}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
      chown ${config.users.users.transmission.name}:${config.users.groups.transmission.name} "$CONFIG_FILE"
      chmod 600 "$CONFIG_FILE"
    '';
    # Keep the default ExecStart as provided by the NixOS module.
    # Do NOT use mkForce to override ExecStart unless you want to completely manage the daemon invocation.
    # The NixOS module for transmission already defines the ExecStart.
  };

  # SOPS configuration
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";

  # CLEANED: Only central secrets (removed service-specific duplicates)
  sops.secrets.zeev_password = {
    neededForUsers = true;
  };
  sops.secrets.nextcloud_admin_password = { };
  sops.secrets.microbin_admin_password = { };
  sops.secrets.tailscale_auth_key = { };
  sops.secrets.pia_credentials = { };
  sops.secrets.telegram_bot_token = { };
  sops.secrets.telegram_chat_id = { };

  # Define groups first
  users.groups = {
    media = { };
    microbin = { };
    miniflux = { };
    samba = { };
    kavita = { };
  };

  # User configuration
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
