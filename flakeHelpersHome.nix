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

  "${userName}@matebook" = helpers.mkStandaloneHome {
    inherit pkgs;
    modules = [
      ./home-manager/matebook
      inputs.betterfox-nix.homeModules.betterfox
    ];
  };
}
