{
  inputs,
  nixpkgs,
  home-manager,
  userName,
  system,
  commonHomeManagerModules,
  commonHomeConfig,
}: let
  # Helper function to create a home-manager configuration
  mkHomeConfig = hostName: extraModules:
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {inherit inputs;};
      modules = [./home/${hostName}] ++ extraModules ++ commonHomeManagerModules ++ [commonHomeConfig];
    };
in {
  homeConfigurations = {
    "${userName}@desktop" = mkHomeConfig "desktop" [
      inputs.plasma-manager.homeModules.plasma-manager
      inputs.betterfox-nix.homeModules.betterfox
      inputs.noctalia.homeModules.default
      inputs.stylix.homeModules.stylix
      inputs.pam-shim.homeModules.default
    ];

    "${userName}@homeserver" = mkHomeConfig "homeserver" [];

    "${userName}@wsl" = mkHomeConfig "wsl" [];

    "${userName}@matebook" = mkHomeConfig "matebook" [
      inputs.betterfox-nix.homeModules.betterfox
    ];
  };
}
