{
  helpers,
  inputs,
  userName,
}: let
  # Use the current system's pkgs instead of hardcoding x86_64-linux
  pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
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
