# File: nixos-config/modules/users/vk/default.nix
{pkgs, ...}: let
  username = "vk";
in {
  environment.shells = with pkgs; [zsh];

  programs.zsh.enable = true;

  system.primaryUser = username;
  users.users.vk = {
    home = "/Users/vk";
    shell = pkgs.zsh;
  };
}
