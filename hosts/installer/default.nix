{pkgs, ...}: {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ../../../modules/users/zeev
  ];

  # Enable experimental features for flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Enable SSH for remote installation
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Set a password for the nixos user
  users.users.nixos.password = "nixos";

  # Add useful packages for installation
  environment.systemPackages = with pkgs; [
    git
    helix
    vim
  ];

  # Use faster mirror
  nix.settings.substituters = lib.mkForce [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];

  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
}
