{ config, pkgs, ... }:

{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}