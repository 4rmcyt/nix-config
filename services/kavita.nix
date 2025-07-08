# /etc/nixos/services/kavita.nix
#
# Configures the Kavita reading server.

{ config, pkgs, ... }:

{
  # Define the system user for Kavita.
  # The 'group' attribute here correctly assigns the user to the 'kavita' group.
  users.users.kavita = {
    isSystemUser = true;
    group = "kavita";
    home = "/var/lib/kavita";
    # Add 'media' to extraGroups to ensure Kavita has access to media directories
    extraGroups = [ "media" ];
  };

  # Define the system group for Kavita.
  users.groups.kavita = {};

  # This block configures the Kavita service itself.
  services.kavita = {
    enable = true;
    # The user that will run the Kavita process.
    user = "kavita";
    # Re-adding 'group' as it is a valid option in recent Nixpkgs versions.
    group = "kavita";
    # Explicitly set the data directory for Kavita. This is crucial for its operation.
    dataDir = "/var/lib/kavita";
  };
}
