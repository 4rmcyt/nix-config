# /etc/nixos/services/kavita.nix
#
# Configures the Kavita reading server.

{ config, pkgs, lib, ... }: # Ensure 'lib' is imported here if not already

{
  # Define the system user for Kavita.
  # The 'group' attribute here correctly assigns the user to the 'kavita' group.
  users.users.kavita = {
    isSystemUser = true;
    group = "kavita";
    # Use lib.mkForce to ensure this definition of 'home' takes precedence
    home = lib.mkForce "/var/lib/kavita";
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
    # This line is removed again as the system consistently reports it as an invalid option.
    # User group membership is handled via 'users.users.kavita.group' and 'extraGroups'.
    
    # Explicitly set the data directory for Kavita. This is crucial for its operation.
    dataDir = "/var/lib/kavita";
    
    # Removed: openFirewall = true;
    # This line is removed because 'services.kavita.openFirewall' is not a valid option.
    # Firewall rules are managed globally via networking.firewall.
  };

  # Open port 5000 for Kavita in the system firewall.
  # This is done at the top-level 'config' block.
  # Changed 'allowedPorts' to 'allowedTCPPorts' as 'allowedPorts' is not a valid option.
  networking.firewall.allowedTCPPorts = [ 5000 ];
  
}
