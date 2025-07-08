{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;

  # Define the complete settings.json content as a Nix string
  # IMPORTANT: All settings must be listed here, as this overrides the module's default settings generation.
  # Use builtins.toJSON for proper JSON formatting.
  transmissionSettingsJson = pkgs.writeText "transmission-daemon-settings.json" (builtins.toJSON {
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
    # --- IMPORTANT: Desired download-dir ---
    download-dir = "/var/lib/transmission/downloads";
    download-queue-enabled = true;
    download-queue-size = 5;
    encryption = 1;
    idle-seeding-limit = 30;
    idle-seeding-limit-enabled = false;
    # --- IMPORTANT: Desired incomplete-dir ---
    incomplete-dir = "/var/lib/transmission/incomplete";
    incomplete-dir-enabled = true;
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
    rpc-authentication-required = false; # Set to true if you want Transmission's built-in login
    rpc-bind-address = "0.0.0.0";
    rpc-enabled = true;
    rpc-host-whitelist = "";
    rpc-host-whitelist-enabled = true;
    # NOTE: We're not setting rpc-password/username here.
    # If you need RPC authentication, you'd need to manually manage
    # this password or use a different mechanism (e.g., Nginx basic auth).
    # Since rpc-authentication-required is false, it's not strictly needed.
    rpc-port = 9091;
    rpc-socket-mode = "0750";
    # --- IMPORTANT: Desired rpc-url ---
    rpc-url = "/";
    rpc-username = "";
    rpc-whitelist = "127.0.0.1"; # Ensure localhost is whitelisted for Cloudflare Tunnel
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
    watch-dir = "/var/lib/transmission/watchdir"; # Ensure this path is correct if used
    watch-dir-enabled = false;
  });
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
      home = "/var/lib/transmission";

      port = 9091; # This port will still be read by the service

      # --- REMOVE THIS 'settings' BLOCK ---
      # settings = {
      #   rpc-enabled = true;
      #   rpc-whitelist-enabled = true;
      #   rpc-whitelist = "127.0.0.1";
      #   rpc-url = "/";
      #   rpc-authentication-required = false;
      #   download-dir = "/var/lib/transmission/downloads";
      #   incomplete-dir-enabled = true;
      #   incomplete-dir = "/var/lib/transmission/incomplete";
      #   peer-port = 51413;
      # };
    };

    users.users.transmission = {
      isSystemUser = true;
      group = "transmission";
      home = "/var/lib/transmission";
    };
    users.groups.transmission = {};

    # Override the default ExecStart to point to our custom settings file
    systemd.services.transmission.extraConfig = ''
      ExecStart=
      ExecStart=${pkgs.transmission_4}/bin/transmission-daemon -f -g ${transmissionSettingsJson}
      # Also add any other ExecStart flags you saw in 'systemctl status' output if needed,
      # like '-l 4' for logging level or '-a' for allowlist directly.
    '';
  } // (mkIf (cfg.enable && cfg.vpn.enable) {
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook
      transmission-remote --peerport "$PORT" || true
    '';

    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

    systemd.services.transmission-daemon = {
      bindsTo = [ "pia-vpn.service" ];
      after = [
        "pia-vpn.service"
        "network-online.target"
      ];
      # These flags are for the service wrapper, not the daemon itself.
      # extraConfig above directly modifies the ExecStart line for the daemon.
    };

    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd
    ];
  });
}
