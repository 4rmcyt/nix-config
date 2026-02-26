{
  config,
  inputs,
  lib,
  ...
}: let
  vmIp = "192.168.200.2";
  bridgeIp = "192.168.200.1";
  inherit (config.my.defaults) domain;
in {
  imports = [inputs.microvm.nixosModules.host];

  # ── Networking: bridge for host ↔ VM ──────────────────────────────────────
  # Switch from dhcpcd to systemd-networkd (required by microvm host module).
  networking.useDHCP = lib.mkForce false;

  systemd.network = {
    enable = true;

    # Physical NIC — keep DHCP for WAN connectivity
    networks."05-wan" = {
      matchConfig.Name = "enp0s31f6";
      networkConfig.DHCP = "ipv4";
      dhcpV4Config.RouteMetric = 100;
    };

    # Bridge netdev for VM
    netdevs."10-br-hass".netdevConfig = {
      Kind = "bridge";
      Name = "br-hass";
    };

    # Assign static IP to bridge
    networks."10-br-hass" = {
      matchConfig.Name = "br-hass";
      addresses = [{Address = "${bridgeIp}/24";}];
      networkConfig = {
        ConfigureWithoutCarrier = true;
        IPv4Forwarding = true;
      };
    };

    # Wire the VM's TAP interface into the bridge
    networks."20-vm-hass0" = {
      matchConfig.Name = "vm-hass0";
      networkConfig.Bridge = "br-hass";
      linkConfig = {
        ActivationPolicy = "always-up";
        RequiredForOnline = "no";
      };
    };
  };

  # NAT masquerade so the VM can reach the internet
  networking.nat = {
    enable = true;
    internalInterfaces = ["br-hass"];
    externalInterface = "enp0s31f6";
  };

  # Allow MQTT and PostgreSQL from bridge subnet only (not exposed on WAN)
  networking.firewall.interfaces."br-hass".allowedTCPPorts = [1883 5432];

  # ── Mosquitto on host (VM connects via bridge IP) ─────────────────────────
  users.users.mosquitto = {
    isSystemUser = true;
    group = "mosquitto";
  };
  users.groups.mosquitto = {};

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        # Bound to bridge IP only — not exposed on the public LAN
        address = bridgeIp;
        port = 1883;
        acl = ["pattern readwrite #"];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  # ── Persistent directories and Traefik dynamic config ────────────────────
  systemd.tmpfiles.rules = [
    "d /var/lib/hass-data          0755 root root -"
    "L+ /var/lib/traefik/hass.yml - - - - /etc/traefik/hass.yml"
  ];

  # Traefik file provider picks this up from the watched directory
  environment.etc."traefik/hass.yml".text = lib.generators.toYAML {} {
    http = {
      routers.hass = {
        rule = "Host(`hass.${domain}`)";
        entryPoints = ["websecure"];
        service = "hass";
        middlewares = ["security-headers"];
        tls = {};
      };
      services.hass.loadBalancer.servers = [{url = "http://${vmIp}:8123";}];
    };
  };

  # ── USB passthrough (add when stick is connected) ────────────────────────
  # 1. Plug in the Z-Wave/Zigbee stick, run `lsusb`, note idVendor:idProduct
  # 2. Add udev rule here:
  #    services.udev.extraRules = ''
  #      SUBSYSTEM=="usb", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="XXXX", MODE="0664", GROUP="kvm"
  #    '';
  # 3. Uncomment qemu.extraArgs in vm-config.nix with the same IDs
  # 4. Uncomment zwave_js / zha in vm-config.nix extraComponents

  # ── microvm definition ────────────────────────────────────────────────────
  # The hass guest is defined as nixosConfigurations.hass in the flake.
  # Using flake = inputs.self avoids inline evaluation cycles.
  microvm.vms.hass = {
    autostart = true;
    flake = inputs.self;
  };
}
