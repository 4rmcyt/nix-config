# HM wiring lives in parts/hm.nix; workstation-specific modules live in parts/workstation.nix.
{inputs, ...}: {
  modules.nixos.base = {
    imports = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
      inputs.nix-topology.nixosModules.default
      ../modules/topology
    ];
  };
}
