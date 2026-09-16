# HM wiring lives in parts/hm.nix; workstation-specific modules live in parts/workstation.nix.
{inputs, ...}: {
  modules.nixos.base = {
    imports = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
      inputs.nix-topology.nixosModules.default
      ../modules/topology
    ];

    # temp shim: sops-nix hardcodes buildGo125Module, removed as EOL upstream; drop once sops-nix bumps it
    nixpkgs.overlays = [
      (final: _prev: {buildGo125Module = final.buildGoModule;})
    ];
  };
}
