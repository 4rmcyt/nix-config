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
  };

  # Define the system group for Kavita.
  users.groups.kavita = {};

  # This block configures the Kavita service itself.
  services.kavita = {
    enable = true;
    # The user that will run the Kavita process.
    user = "kavita";
    # Removed: group = "kavita";
    # This line is removed because 'services.kavita.group' is not a valid option
    # in the NixOS Kavita module. The user's group is already handled by
    # 'users.users.kavita.group' above.
    
    # This opens port 5000 in the firewall. While not strictly necessary
    # when using Cloudflare Tunnels, it's good practice for local access.
    openFirewall = true;
  };
  
}
