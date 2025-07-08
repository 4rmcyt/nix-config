{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;

  # Define the COMPLETE desired settings.json content as a Nix string.
  # This will be the *sole source of truth* for Transmission's settings.
  # Ensure all your desired settings are correctly reflected here.
  transmissionSettingsContent = builtins.toJSON {
    alt-speed-down = 50;
    alt-speed-enabled = false;
    alt-speed-time-begin = 540;
    alt-speed-time-day = 127;
    alt-speed-time-enabled = false;
    alt-speed-time-end = 1020;
    alt-speed-up = 50;
    announce-ip = "";
    announce-ip-enabled = false;
    anti-brute-force-enabled = false;
    anti-brute-force-threshold = 100;
    bind-address-ipv4 = "0.0.0.0";
    bind-address-ipv6 = "::";
    blocklist-enabled = false;
    blocklist-url = "http://www.example.com/blocklist";
    cache-size-mb = 4;
    default-trackers = "";
    dht-enabled = true;
    # --- YOUR DESIRED DOWNLOAD DIRECTORY ---
    download-dir = "/home/zeev/Downloads";
    download-queue-enabled = true;
    download-queue-size = 5;
    encryption = 1;
    idle-seeding-limit = 30;
    idle-seeding-limit-enabled = false;
    # --- YOUR DESIRED INCOMPLETE DIRECTORY ---
    incomplete-dir = "/home/zeev/Downloads/incomplete";
    incomplete-dir-enabled = false;
    lpd-enabled = true;
    message-level = 2;
    peer-congestion-algorithm = "";
    peer-limit-global = 200;
    peer-limit-per-torrent = 50;
    peer-port = 51413;
    peer-port-random-high = 65535;
    peer-port-random-low = 65535;
    peer-port-random-on-start = false;
    peer-socket-tos = "le";
    pex-enabled = true;
    port-forwarding-enabled = true;
    preallocation = 1;
    prefetch-enabled = true;
    queue-stalled-enabled = true;
    queue-stalled-minutes = 30;
    ratio-limit = 2;
    ratio-limit-enabled = false;
    rename-partial-files = false;
    rpc-authentication-required = false;
    rpc-bind-address = "0.0.0.0";
    rpc-enabled = true;
    rpc-host-whitelist = "";
    rpc-host-whitelist-enabled = true;
    # You had a password in settings.json. If you need one, set rpc-authentication-required = true and provide username/password.
    # For now, keeping rpc-authentication-required = false.
    # rpc-password = "{HASHED_PASSWORD_FROM_TRANSMISSION}"; # DO NOT put plaintext here!
    # rpc-username = "someuser";
    rpc-port = 9091;
    rpc-socket-mode = "0750";
    # --- CRUCIAL: RPC URL for Cloudflare Tunnel direct proxy ---
    rpc-url = "/";
    rpc-username = ""; # Blank if authentication is not required
    rpc-whitelist = "127.0.0.1,10.0.0.1,192.168.1.0/24,100.64.0.0/10"; # Ensure 127.0.0.1 is here
    rpc-whitelist-enabled = true;
    scrape-paused-torrents-enabled = true;
    script-torrent-added-enabled = false;
    script-torrent-added-filename = "";
    script-torrent-done-enabled = false;
    script-torrent-done-filename = "";
    script-torrent-done-seeding-enabled = false;
    script-torrent-done-seeding-filename = "";
    seed-queue-enabled = false;
    seed-queue-size = 10;
    speed-limit-down = 100;
    speed-limit-down-enabled = false;
    speed-limit-up = 100;
    speed-limit-up-enabled = false;
    start-added-torrents = true;
    tcp-enabled = true;
    torrent-added-verify-mode = "fast";
    trash-original-torrent-files = false;
    umask = "022";
    upload-slots-per-torrent = 8;
    utp-enabled = true;
    # --- YOUR DESIRED WATCH DIRECTORY ---
    watch-dir = "/home/zeev/Downloads/torrents";
    watch-dir-enabled = false; # Set to true to enable watching
  });

  # This creates a *directory* in the Nix store that contains our settings.json file.
  # Transmission's -g flag expects a directory.
  transmissionConfigDir = pkgs.runCommand "transmission-config-dir" {} ''
    mkdir -p $out/transmission-daemon
    echo "$transmissionSettingsContent" > $out/transmission-daemon/settings.json
    # Set permissions so Transmission user can read this config file
    chmod 0444 $out/transmission-daemon/settings.json
  '';

in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  config = {
    services.transmission = {
      enable = true;
      user = "transmission";
      group = "transmission";
      home = "/var/lib/transmission"; # This is the service user's home, not for downloads

      port = 9091; # This port will still be read by the service

      # === CRITICAL OVERRIDE: Force Transmission to use our generated config file ===
      # This completely replaces the default ExecStart defined by the NixOS module.
      systemd.serviceConfig.ExecStart = [
        "" # This empty string effectively clears any inherited ExecStart commands
        "${pkgs.transmission_4}/bin/transmission-daemon -f -g ${transmissionConfigDir}/transmission-daemon"
        # Add any other necessary flags that might be missing from the original ExecStart,
        # but -f (foreground) and -g (config directory) are the most important.
      ];

      # Remove the 'settings' attribute. It is no longer used, as we manage the config file directly.
      # settings = { ... };

      # Common systemd dependencies and orderings directly under services.transmission
      bindsTo = lib.mkIf cfg.vpn.enable [ "pia-vpn.service" ];
      after = [ "network-online.target" ]
              ++ lib.mkIf cfg.vpn.enable [ "pia-vpn.service" ];
    };

    users.users.transmission = {
      isSystemUser = true;
      group = "transmission";
      home = "/var/lib/transmission";
      extraGroups = [ "users" "pia-vpn" "media" ]; # Ensure 'users' for /home/zeev/ access
    };
    users.groups.transmission = {};

  } // (mkIf (cfg.enable && cfg.vpn.enable) {
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook
      transmission-remote --peerport "$PORT" || true
    '';

    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd
    ];
  });
}