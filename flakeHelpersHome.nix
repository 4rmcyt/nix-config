{
  helpers,
  inputs,
  userName,
}: let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
in {
  "${userName}@desktop" = helpers.mkStandaloneHome {
    inherit pkgs;
    modules = [
      ./home-manager/desktop
      inputs.plasma-manager.homeModules.plasma-manager
      inputs.nixai.homeManagerModules.default
      inputs.betterfox-nix.homeModules.betterfox
    ];
  };

  "${userName}@homeserver" = helpers.mkStandaloneHome {
    inherit pkgs;
    modules = [./home-manager/homeserver];
  };

  "${userName}@wsl" = helpers.mkStandaloneHome {
    inherit pkgs;
    modules = [./home-manager/wsl];
  };

  "${userName}@laptop" = helpers.mkStandaloneHome {
    inherit pkgs;
    modules = [./home-manager/laptop];
  };
}
