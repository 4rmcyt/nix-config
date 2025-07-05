
{ config, pkgs, lib, ... }:

{
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 8085;
  };

  # Add the audiobookshelf user to media group
  users.users.audiobookshelf.extraGroups = [ "media" ];

  # REMOVED: Media directories (now handled centrally in configuration.nix)
  # This prevents permission conflicts

  # REMOVED: Firewall port (now handled centrally in networking.nix)
}