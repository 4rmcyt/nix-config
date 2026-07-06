# Router Installation Guide

**Hardware:** Sophos SG110/120 — Intel Atom D525, legacy BIOS, VGA output, 4x Intel 82583V NICs (e1000e).

## 1. Boot NixOS minimal ISO (x86_64)

Write to USB and boot. At the console, set a password for SSH access from desktop:

```bash
passwd nixos
```

Get the IP assigned by the ISP router (live ISO may not auto-configure DHCP):

```bash
ip link                   # find the connected interface name
dhcpcd <interface>        # request IP from ISP router
ip addr                   # confirm IP assigned
```

## 2. Identify interfaces and disk

Map physical ports by plugging a cable into each one and watching which interface gets carrier:

```bash
watch -n1 'ip link | grep -E "enp|state"'
```

Note the disk device:

```bash
lsblk -d -o NAME,SIZE,MODEL,SERIAL
```

## 3. Fill in placeholders

**`hosts/nixos/router/networking.nix`** — set interface variables:
```nix
wanInterface   = "enp5s0";  # WAN
trunkInterface = "enp4s0";  # office trunk → TL-SG108E #1
mediaInterface = "enp3s0";  # media switch → TL-SG108E #2
apInterface    = "enp2s0";  # ISP AP (trusted WiFi)
```

**`networking.hostId`** — generate:
```bash
head -c4 /dev/urandom | od -A none -t x4 | tr -d ' \n'
```

**`modules/disko/router/default.nix`** — set disk device (use `/dev/sda` for bare install):
```nix
device = "/dev/sda";
```

## 4. Install via nixos-anywhere (from desktop)

**Critical:** pass the age key via `--extra-files` so sops works on first boot.

```bash
mkdir -p /tmp/router-extra/root/.config/sops/age
cp ~/.config/sops/age/keys.txt /tmp/router-extra/root/.config/sops/age/keys.txt

nix run github:nix-community/nixos-anywhere -- \
  --flake .#router \
  --extra-files /tmp/router-extra \
  nixos@<sophos-ip>
```

nixos-anywhere runs disko (partition + format), copies extra files, installs NixOS, reboots.

## 5. After first boot

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

## 6. Run nixos-facter (optional, improves hardware detection)

```bash
ssh zeev@192.168.1.1
nix run github:nix-community/nixos-facter -- -o /tmp/facter.json
```

Copy `facter.json` to `hosts/nixos/router/facter.json` in the flake.

## 7. Configure switches

Factory reset both switches. They'll get their IPs via ISP router DHCP until the NixOS router takes over.

```bash
SW1_PASS=sw1_SeptuagintA ./scripts/switch-office-setup.sh
SW2_PASS=sw2_SeptuagintA ./scripts/switch-living-room-setup.sh
```

After `switch-living-room-setup.sh` completes, LivingRoom_SW2 moves to `192.168.30.112` and is only reachable from the media segment.

## 8. Rebuild homeserver

Apply the new NFS export for media segment:

```bash
# on homeserver — check for active ZFS transfers first
systemctl list-units --type=mount
nixos-rebuild boot
# reboot at a convenient time
```
