inputs:
let
  homeManagerCfg = userPackages: extraImports: {
    home-manager.useGlobalPkgs = false;
    home-manager.extraSpecialArgs = {
      inherit inputs;
    };
    home-manager.users.zeev.imports = [
      inputs.nix-index-database.homeModules.nix-index
      ./users/zeev
      sops-nix.homeManagerModules.sops
    ] ++ extraImports;
    sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
    home-manager.useUserPackages = userPackages;
  };
in
{

  mkDarwin = machineHostname: nixpkgsVersion: extraHmModules: extraModules: {
    darwinConfigurations.${machineHostname} = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        inputs.agenix.darwinModules.default
        ./hosts/darwin/${machineHostname}
        inputs.home-manager-unstable.darwinModules.home-manager
        (nixpkgsVersion.lib.attrsets.recursiveUpdate (homeManagerCfg true extraHmModules) {
          home-manager.users.vk.home.homeDirectory = nixpkgsVersion.lib.mkForce "/Users/vk";
        })
      ];
    };
  };
  mkNixos = machineHostname: nixpkgsVersion: extraModules: {
    nixosConfigurations.${machineHostname} = nixpkgsVersion.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./hosts/nixos/${machineHostname}
        ./modules/users/zeev
        auto-cpufreq.nixosModules.default
         "${inputs.linkwarden-pr}/nixos/modules/services/web-apps/linkwarden.nix"
        inputs.nixos-facter-modules.nixosModules.facter
        { facter.reportPath = ./facter.json; }
        (homeManagerCfg false [ ])
      ] ++ extraModules;
    };
  };
  mkMerge = inputs.nixpkgs.lib.lists.foldl' (
    a: b: inputs.nixpkgs.lib.attrsets.recursiveUpdate a b
  ) { };
}