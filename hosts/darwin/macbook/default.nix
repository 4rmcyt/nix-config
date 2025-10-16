{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../../modules/nix-darwin
  ];

  # Enable experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;

  # Necessary for using flakes on this system
  nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing
  system.stateVersion = 5;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.zeev = import ../../../home-manager/darwin;
    extraSpecialArgs = {
      inherit inputs;
    };
  };
}
