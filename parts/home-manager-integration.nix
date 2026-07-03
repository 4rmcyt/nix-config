# Base NixOS module imports applied to all hosts.
# HM wiring lives in parts/hm.nix (modules.nixos.hm) — imported only on hosts that use HM.
# Workstation-specific modules (ucodenix, facter, gnupg, nh) live in parts/workstation.nix.
{inputs, ...}: {
  modules.nixos.base = {
    imports = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
      inputs.nix-topology.nixosModules.default
    ];
  };
}
