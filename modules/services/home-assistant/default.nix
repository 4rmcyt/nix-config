{
  config,
  lib,
  pkgs,
  ...
}: let
  # HAOS gets its own IP from router DHCP via br0.
  # Set a static DHCP reservation on your router and update this value.
  hassIp = "192.168.1.235";
  hassVersion = "17.1";
  hassImageUrl = "https://github.com/home-assistant/operating-system/releases/download/${hassVersion}/haos_ova-${hassVersion}.qcow2.xz";
  hassImage = "/var/lib/libvirt/images/haos_ova-${hassVersion}.qcow2";
  inherit (config.my.defaults) domain homeserver_lan gateway;
in {
  # ── Networking: bridge host NIC so HAOS appears on the LAN ───────────────
  # enp0s31f6 becomes a bridge port; host and HAOS each get separate LAN IPs.
  # Using networkd (consistent with previous config that had systemd.network.enable = true).
  networking.useDHCP = lib.mkForce false;

  systemd.network = {
    enable = true;

    # Bridge netdev
    netdevs."10-br0".netdevConfig = {
      Kind = "bridge";
      Name = "br0";
    };

    # Enslave physical NIC into bridge — no IP on this interface
    networks."05-enp0s31f6" = {
      matchConfig.Name = "enp0s31f6";
      networkConfig.Bridge = "br0";
      linkConfig = {
        ActivationPolicy = "always-up";
        RequiredForOnline = "no";
      };
    };

    # Bridge gets the host's static LAN IP
    networks."10-br0" = {
      matchConfig.Name = "br0";
      address = ["${homeserver_lan}/24"];
      routes = [{Gateway = gateway;}];
      networkConfig.ConfigureWithoutCarrier = true;
    };
  };

  # ── libvirt ───────────────────────────────────────────────────────────────
  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };

  environment.systemPackages = with pkgs; [
    bridge-utils
    virt-manager # provides virt-install
    libvirt # provides virsh
  ];

  # libvirt bridged-network XML — forward mode=bridge ties into host br0
  environment.etc."libvirt/bridged-network.xml".text = ''
    <network>
      <name>bridged-network</name>
      <forward mode="bridge"/>
      <bridge name="br0"/>
    </network>
  '';

  # ── Bootstrap HAOS VM (idempotent oneshot) ───────────────────────────────
  systemd.services.hass-vm-setup = {
    description = "Bootstrap Home Assistant OS VM via libvirt";
    after = ["libvirtd.service" "network-online.target"];
    wants = ["libvirtd.service" "network-online.target"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [curl xz coreutils libvirt virt-manager];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail

      # Idempotent: skip if VM already exists
      if virsh --connect qemu:///system list --all | grep -qw "hass"; then
        echo "hass VM already exists, nothing to do"
        exit 0
      fi

      # Define bridged network if not present
      if ! virsh --connect qemu:///system net-list --all | grep -qw "bridged-network"; then
        virsh --connect qemu:///system net-define /etc/libvirt/bridged-network.xml
        virsh --connect qemu:///system net-start bridged-network
        virsh --connect qemu:///system net-autostart bridged-network
      fi

      # Download HAOS image
      if [ ! -f "${hassImage}" ]; then
        echo "Downloading HAOS ${hassVersion}..."
        mkdir -p "$(dirname "${hassImage}")"
        curl -L -o "${hassImage}.xz" "${hassImageUrl}"
        xz -d "${hassImage}.xz"
      fi

      # Create VM
      virt-install \
        --connect qemu:///system \
        --name hass \
        --boot uefi \
        --import \
        --disk "${hassImage},format=qcow2,bus=virtio" \
        --cpu host \
        --vcpus 2 \
        --memory 2048 \
        --network network=bridged-network \
        --graphics spice,listen=127.0.0.1 \
        --noautoconsole \
        --os-variant generic

      virsh --connect qemu:///system autostart hass
      echo "Done — hass VM created and set to autostart"
    '';
  };

  # ── Mosquitto on host (HAOS connects via host LAN IP) ────────────────────
  users.users.mosquitto = {
    isSystemUser = true;
    group = "mosquitto";
  };
  users.groups.mosquitto = {};

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = homeserver_lan;
        port = 1883;
        acl = ["pattern readwrite #"];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  networking.firewall.interfaces."br0".allowedTCPPorts = [1883];

  # ── Traefik dynamic config ────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "L+ /var/lib/traefik/hass.yml - - - - /etc/traefik/hass.yml"
  ];

  environment.etc."traefik/hass.yml".text = lib.generators.toYAML {} {
    http = {
      routers.hass = {
        rule = "Host(`hass.${domain}`)";
        entryPoints = ["websecure"];
        service = "hass";
        middlewares = ["security-headers"];
        tls = {};
      };
      services.hass.loadBalancer.servers = [{url = "http://${hassIp}:8123";}];
    };
  };

  # ── USB passthrough (Zigbee/Z-Wave dongle) ───────────────────────────────
  # virsh --connect qemu:///system attach-device hass usb-device.xml --persistent
}
