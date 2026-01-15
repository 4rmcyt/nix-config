{
  inputs,
  nixpkgs,
  home-manager,
  userName,
  system,
  commonHomeManagerModules,
}: let
  # Common home configuration for standalone home-manager
  commonHomeConfig = {
    _module.args = {inherit inputs;};
    home = {
      username = userName;
      homeDirectory = "/home/${userName}";
      stateVersion = "24.11";
    };
    nixpkgs.config.allowUnfree = true;
    sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";

    # Add firefox-nightly to pkgs via overlay
    nixpkgs.overlays = [
      (_final: prev: {
        firefox-nightly = inputs.firefox-nightly.packages.${system}.firefox-nightly-bin or prev.firefox;
      })
    ];
  };

  # Helper function to create a home-manager configuration
  mkHomeConfig = hostName: extraModules:
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {inherit inputs;};
      modules =
        [
          ./home/${hostName}
        ]
        ++ extraModules
        ++ commonHomeManagerModules
        ++ [commonHomeConfig];
    };
in {
  homeConfigurations = {
    "${userName}@desktop" = mkHomeConfig "desktop" [
      inputs.plasma-manager.homeModules.plasma-manager
      inputs.betterfox-nix.homeModules.betterfox
      inputs.stylix.homeModules.stylix
      inputs.pam-shim.homeModules.default
      inputs.dms.homeModules.dank-material-shell
    ];

    "${userName}@homeserver" = mkHomeConfig "homeserver" [];

    "${userName}@wsl" = mkHomeConfig "wsl" [];

    "${userName}@matebook" = mkHomeConfig "matebook" [
      inputs.betterfox-nix.homeModules.betterfox
    ];
  };
}
