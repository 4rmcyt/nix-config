# Actual hardening settings live per-host in hosts/nixos/<host>/hardening.nix, since
# filesystem/network overrides differ too much to share.
{inputs, ...}: {
  modules.nixos.nixMineral.imports = [
    inputs.nix-mineral.nixosModules.nix-mineral
  ];
}
