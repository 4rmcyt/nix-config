# Router Installation Guide

**Hardware:** Sophos SG110/120 — Intel Atom D525, legacy BIOS, VGA output.

## 1. Boot NixOS minimal ISO (x86_64)

Write to USB and boot. At the console:

```bash
# Set password for SSH access from desktop (optional)
passwd nixos
```

## 2. Identify interfaces and disk

```bash
ip link                              # note all interface names (enp*s*)
lsblk -d -o NAME,SIZE,MODEL,SERIAL  # note disk for disko
```

Map physical ports by plugging a cable into each one and watching which interface gets carrier:

```bash
watch -n1 'ip link | grep -E "enp|state"'
```

Expected layout (verify on hardware):

| Interface | Role |
|-----------|------|
| `enp1s0` | WAN |
| `enp2s0` | Office trunk → TL-SG108E #1 |
| `enp3s0` | Media → TL-SG108E #2 |
| `enp4s0` | ISP AP (trusted WiFi) |

## 3. Fill in placeholders

**`hosts/nixos/router/networking.nix`** — set interface variables:
```nix
wanInterface   = "enp1s0";  # WAN
trunkInterface = "enp2s0";  # office trunk
mediaInterface = "enp3s0";  # media switch
apInterface    = "enp4s0";  # ISP AP
```

**`hosts/nixos/router/networking.nix`** — generate and set hostId:
```bash
head -c4 /dev/urandom | od -A none -t x4 | tr -d ' \n'
```

**`hosts/nixos/router/firewall.nix`** — update interface defines to match above.

**`hosts/nixos/router/default.nix`** — update `networking.tailscaleAuth.networkInterface`.

**`modules/disko/router/default.nix`** — set disk device:
```nix
device = "/dev/disk/by-id/<id-from-lsblk>";
```

## 4. Generate hardware-configuration.nix

```bash
nixos-generate-config --no-filesystems --root /mnt
```

Copy `/mnt/etc/nixos/hardware-configuration.nix` to `hosts/nixos/router/hardware-configuration.nix` in the flake. Commit everything.

## 5. Install via nixos-anywhere (from desktop)

Get the Sophos IP from the ISP router DHCP table, then:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#router \
  nixos@<sophos-ip>
```

nixos-anywhere runs disko (partition + format), installs NixOS, reboots.

## 6. After first boot

```bash
ssh zeev@192.168.1.1

# Verify interfaces
ip addr
networkctl status

# Verify nftables
nft list ruleset

# Verify DHCP
systemctl status kea-dhcp4-server

# Verify DNS
systemctl status unbound
dig @192.168.1.1 example.com
```

## 7. Configure switches

Factory reset both switches first — they'll get their IPs back via ISP router DHCP MAC reservations.

```bash
SW1_PASS=<password> ./scripts/switch-office-setup.sh
SW2_PASS=<password> ./scripts/switch-media-setup.sh
```

After `switch-media-setup.sh` completes, LivingRoom_SW2 moves to `192.168.30.112` and is only reachable from the media segment.

## 8. Rebuild homeserver

Apply the new NFS export for media segment:

```bash
# on homeserver
nixos-rebuild boot
# reboot at a convenient time
```
