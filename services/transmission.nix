{ config, lib, pkgs, ... }: # Ensure 'lib' is in the arguments

with lib;

let
  cfg = config.services.transmission; # Reference to the enabled transmission service config
in
{
  # == 1. Define custom option for VPN (correct structure) ==
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  # == 2. Core Configuration Block ==
  # All non-conditional configuration goes here.
  # The conditional VPN part will be merged into this using '//'.
  config = {
    services.transmission = {
      enable = true; # Explicitly enable the Transmission service
      user = "transmission"; # Daemon user
      group = "transmission"; # Daemon group
      home = "/var/lib/transmission"; # Transmission's primary data directory

      port = 9091; # Transmission's RPC port (Cloudflare Tunnel forwards to this)

      # --- Essential Transmission Settings ---
      settings = {
        rpc-enabled = true;
       # Whitelist for Cloudflare Tunnel (127.0.0.1) and your local network
        rpc-whitelist = "127.0.0.1,10.0.0.1,192.168.1.0/24,100.64.0.0/10,localhost";
        # CRUCIAL for Cloudflare Tunnel direct access: Serve web UI from root path
        rpc-url = "/";
        rpc-authentication-required = false; # Set to true if you want Transmission's built-in login

        # Your desired download, incomplete, and watch directories
        download-dir = "/home/zeev/Downloads";
        incomplete-dir-enabled = true;
        incomplete-dir = "/home/zeev/Downloads/incomplete";
        watch-dir = "/home/zeev/Downloads/torrents";
        watch-dir-enabled = true; # Set to true if you want Transmission to auto-load .torrent files

        # Other standard settings (copied from your previous settings.json for consistency)
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
        encryption = 1;
        idle-seeding-limit = 30;
        idle-seeding-limit-enabled = false;
        lpd-enabled = true;
        message-level = 2;
        peer-congestion-algorithm = "";
        peer-limit-global = 200;
        peer-limit-per-torrent = 50;
        peer-port = 51413; # This peer port will be updated by PIA VPN hook
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
        rpc-bind-address = "0.0.0.0"; # Bind RPC to all interfaces (safe as whitelist limits access)
        rpc-host-whitelist = "";
        rpc-host-whitelist-enabled = true;
        rpc-username = "";
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
      };

      # Systemd dependencies for the Transmission service
      systemd.services.transmission.bindsTo = lib.mkIf cfg.vpn.enable [ "pia-vpn.service" ];
      systemd.services.transmission.after = [ "network-online.target" ]
                                             ++ lib.mkIf cfg.vpn.enable [ "pia-vpn.service" ];
    };

    # == 3. Transmission User and Group Definition ==
    users.users.transmission = {
      isSystemUser = true;
      group = "transmission";
      home = "/var/lib/transmission"; # Service user's home directory
      # Add 'users' group for access to /home/zeev/Downloads (assuming 'zeev' is in 'users' group)
      # Also keep 'pia-vpn' for VPN routing and 'media' for other media access.
      extraGroups = [ "users" "pia-vpn" "media" ];
    };
    users.groups.transmission = {};

  } // (mkIf (cfg.enable && cfg.vpn.enable) {
    # == 4. Conditional PIA VPN Integration (your existing logic) ==
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook
      transmission-remote --peerport "$PORT" || true
    '';

    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd # for systemd-cat
    ];
  });
}