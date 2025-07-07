# /etc/nixos/services/kavita.nix
#
# Configures the Kavita reading server.

{ config, pkgs, ... }:

{
  users.users.kavita = {
    isSystemUser = true;
    group = "kavita";
    home = "/var/lib/kavita";
  };

  users.groups.kavita = {};
  # This block configures the Kavita service itself.
  services.kavita = {
    enable = true;
    # The user and group that will run the Kavita process.
    user = "kavita";
    group = "kavita";
    # This opens port 5000 in the firewall. While not strictly necessary
    # when using Cloudflare Tunnels, it's good practice for local access.
    openFirewall = true;
  };
  
}
