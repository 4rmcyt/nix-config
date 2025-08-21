inputs:
let
  homeManagerCfg = user: host: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${user} = {
      imports = [
        ./modules/home-manager/${host}
        inputs.sops-nix.homeManagerModules.sops
      ];
      sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
    };
  };

  commonNixOSModules = [
    inputs.sops-nix.nixosModules.sops
    { sops.age.keyFile = "/var/lib/sops/age.key"; }
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    inputs.nix-index-database.nixosModules.nix-index
    inputs.auto-cpufreq.nixosModules.default
    "${inputs.linkwarden-pr}/nixos/modules/services/web-apps/linkwarden.nix"
    inputs.nixos-facter-modules.nixosModules.facter
    { facter.reportPath = ./facter.json; }
  ];
in
{
  mkNixos = machineHostname: nixpkgsVersion: extraModules: {
    nixosConfigurations.${machineHostname} = nixpkgsVersion.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        host = machineHostname;
      };
      modules = commonNixOSModules ++ [
        (homeManagerCfg "zeev" machineHostname)
      ] ++ extraModules;
    };
  };
  mkMerge = inputs.nixpkgs.lib.lists.foldl' (
    a: b: inputs.nixpkgs.lib.attrsets.recursiveUpdate a b
  ) { };
}