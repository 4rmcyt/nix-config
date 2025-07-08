{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;

  # This now contains JUST the JSON string content.
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
    download-dir = "/var/lib/transmission/downloads"; # YOUR DESIRED PATH
    download-queue-enabled = true;
    download-queue-size = 5;
    encryption = 1;
    idle-seeding-limit = 30;
    idle-seeding-limit-enabled = false;
    incomplete-dir = "/var/lib/transmission/incomplete"; # YOUR DESIRED PATH
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
    rpc-authentication-required = false;
    rpc-bind-address = "0.0.0.0";
    rpc-enabled = true;
    rpc-host-whitelist = "";
    rpc-host-whitelist-enabled = true;
    rpc-port = 9091;
    rpc-url = "/"; # YOUR DESIRED PATH
    rpc-username = "";
    rpc-whitelist = "127.0.0.1";
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
    watch-dir = "/var/lib/transmission/watchdir";
    watch-dir-enabled = false;
  });

  # This creates a DIRECTORY in the Nix store containing the settings.json file.
  transmissionConfigDir = pkgs.runCommand "transmission-config-dir" {} ''
    mkdir -p $out/transmission-daemon
    echo "$transmissionSettingsContent" > $out/transmission-daemon/settings.json
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
      home = "/var/lib/transmission";

      port = 9091;

      # THIS IS THE CORRECT WAY TO OVERRIDE ExecStart
      systemd.serviceConfig.ExecStart = [ # Use a list to clear previous ExecStart
        "" # This empty string resets any inherited ExecStart definitions
        # Pass the *directory* containing settings.json to -g
        "${pkgs.transmission_4}/bin/transmission-daemon -f -g ${transmissionConfigDir}/transmission-daemon"
      ];
      # The 'settings' attribute is implicitly ignored if ExecStart is set this way.
      # You can remove or comment it out entirely to avoid confusion.
      # settings = { ... };

      # Conditional systemd dependencies and orderings are now handled here
      bindsTo = lib.mkIf cfg.vpn.enable [ "pia-vpn.service" ];
      after = [ "network-online.target" ]
              ++ lib.mkIf cfg.vpn.enable [ "pia-vpn.service" ];
    };

    users.users.transmission = {
      isSystemUser = true;
      group = "transmission";
      home = "/var/lib/transmission";
    };
    users.groups.transmission = {};

  } // (mkIf (cfg.enable && cfg.vpn.enable) {
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook
      transmission-remote --peerport "$PORT" || true
    '';

    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd
    ];
  });
}