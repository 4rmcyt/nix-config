# Deferred module: opts a host into inputs.nix-mineral's NixOS module.
# Wired into desktop, gcp-relay, homeserver (parts/hosts/<host>/configuration.nix)
# — not matebook (not planned). Actual hardening settings live per-host in
# hosts/nixos/<host>/hardening.nix, since filesystem/network overrides differ
# too much to share (ZFS vs Btrfs vs single-partition, exit-node routing, …).
{inputs, ...}: {
  modules.nixos.nixMineral.imports = [
    inputs.nix-mineral.nixosModules.nix-mineral
  ];
}
