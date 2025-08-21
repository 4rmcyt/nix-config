# File: nixos-config/hosts/darwin/macbook/default.nix
{
  pkgs,
  lib,
  inputs,
  ...
}: {
  # --------------------------------------------------------------------------------
  # System & User Configuration
  # --------------------------------------------------------------------------------

  networking.hostName = "macbook";
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # ADD THIS BLOCK to use the custom Firefox
  nixpkgs.overlays = [inputs.firefox-darwin.overlay];
  users.users.vk = {
    name = "vk";
    home = "/Users/vk";
  };
  environment.shellInit = ''
    ulimit -n 2048
  '';
  # --------------------------------------------------------------------------------
  # Nix Configuration (System-Wide)
  # --------------------------------------------------------------------------------
  nix.package = pkgs.nix;
  nix.settings = {
    trusted-users = [
      "root"
      "vk"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
  };

  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 1w";
  };
  nix.optimise.automatic = true;

  # --------------------------------------------------------------------------------
  # Homebrew Management (System-Wide Integration)
  # --------------------------------------------------------------------------------
  nix-homebrew = {
    enable = true;
    user = "vk";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };
}
