# Guest NixOS module for the Home Assistant microvm.
# Called as a function from default.nix so host-level values (domain,
# bridgeIp, etc.) can be captured via closure without needing my.defaults.*
# inside the guest's independent module system.
{
  domain,
  tz,
  bridgeIp, # host bridge IP — gateway, Mosquitto broker, PostgreSQL
  vmIp, # this VM's static IP
  vmMac, # MAC address matching the TAP definition on the host
  homeserverLan, # host LAN IP — used for internal_url
}: {
  pkgs,
  ...
}: {
  # ── microvm hypervisor settings ───────────────────────────────────────────
  microvm = {
    hypervisor = "qemu";
    vcpus = 2;
    mem = 2048;

    # Share the host Nix store read-only — fast rebuilds, no per-VM squashfs
    shares = [
      {
        proto = "virtiofs";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
      # Persistent HA state on host filesystem (ZFS-snapshotable)
      {
        proto = "virtiofs";
        tag = "hass-data";
        source = "/var/lib/microvms/hass/data";
        mountPoint = "/var/lib/hass";
      }
    ];
    writableStoreOverlay = "/nix/.rw-store";

    interfaces = [
      {
        type = "tap";
        id = "vm-hass0"; # must match the TAP name in the host's systemd.network
        mac = vmMac;
      }
    ];

    # USB passthrough — fill in vendorid/productid from `lsusb` on the host.
    # Common sticks:
    #   Zooz ZST10 700 series:    vendorid=0x10c4 productid=0xea60
    #   Aeotec Z-Stick Gen5+:     vendorid=0x0658 productid=0x0200
    #   HUSBZB-1 (Z-Wave+Zigbee): vendorid=0x10c4 productid=0x8a2a
    qemu.extraArgs = [
      # "-usb"
      # "-device" "usb-host,vendorid=0xXXXX,productid=0xXXXX"
    ];
  };

  # ── Filesystem ────────────────────────────────────────────────────────────
  fileSystems."/" = {
    device = "rootfs";
    fsType = "tmpfs";
    options = ["defaults" "mode=755"];
  };

  # ── Networking — static IP on the host bridge ─────────────────────────────
  networking = {
    hostName = "hass-vm";
    useDHCP = false;
    enableIPv6 = false;
    nameservers = ["1.1.1.1" "8.8.8.8"];
    firewall.allowedTCPPorts = [8123];
  };

  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.MACAddress = vmMac;
      addresses = [{Address = "${vmIp}/24";}];
      routes = [{Gateway = bridgeIp;}];
      linkConfig.RequiredForOnline = "routable";
    };
  };

  # ── Home Assistant ────────────────────────────────────────────────────────
  services.home-assistant = {
    enable = true;
    configDir = "/var/lib/hass";
    configWritable = true;

    extraPackages = ps:
      with ps; [
        psycopg2 # PostgreSQL driver
        pyatv # Apple TV
      ];

    extraComponents = [
      "mqtt"
      "http"
      "roku"
      "alexa_devices"
      "upnp"
      "radio_browser"
      "met"
      "paperless_ngx"
      "playstation_network"
      "jellyfin"
      # Uncomment after filling in USB device IDs above:
      # "zwave_js"
      # "zha"
    ];

    config = {
      homeassistant = {
        name = "Lab Home";
        unit_system = "metric";
        time_zone = tz;
        country = "CA";
        currency = "CAD";
        external_url = "https://hass.${domain}";
        # Internal URL uses the host LAN IP via Traefik
        internal_url = "http://${homeserverLan}:8123";
      };

      # PostgreSQL on host, trusted from bridge subnet (no password needed)
      recorder.db_url = "postgresql://hass@${bridgeIp}/hass";

      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          bridgeIp # Traefik runs on the host bridge gateway
          homeserverLan # direct LAN access
        ];
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };

      # Mosquitto is on the host, reachable via bridge gateway IP
      mqtt = {
        broker = bridgeIp;
        port = 1883;
      };

      tts = [
        {
          platform = "google_translate";
          language = "en";
        }
      ];

      default_config = {};
      frontend.themes = "!include_dir_merge_named themes";
      shopping_list = {};
      map = {};
      system_health = {};
      logger = {
        default = "info";
        logs."homeassistant.core" = "debug";
      };
    };
  };

  # ── Base VM settings ──────────────────────────────────────────────────────
  time.timeZone = tz;
  system.stateVersion = "25.05";

  environment.systemPackages = with pkgs; [
    curl
    iproute2
  ];
}
