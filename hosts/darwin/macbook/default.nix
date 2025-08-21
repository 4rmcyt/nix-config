# File: nixos-config/hosts/darwin/macbook/default.nix
{ pkgs, ... }: {
  # System & User Configuration
  networking.hostName = "macbook";
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  users.users.vk = {
    name = "vk";
    home = "/Users/vk";
  };

  # Nix Configuration
  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [ "root" "vk" ];
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 1w";
    };
    optimise.automatic = true;
  };

  # Homebrew Management
  nix-homebrew = {
    enable = true;
    user = "vk";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # Shells
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];
}