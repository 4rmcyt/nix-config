{...}: {
  # Avahi - mDNS/DNS-SD service discovery
  # Enables .local hostname resolution and service discovery across the network
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable mDNS resolution for .local domains (IPv4)
    openFirewall = true; # Open UDP port 5353 for mDNS
    publish = {
      enable = true;
      addresses = true; # Publish this host's addresses
      workstation = true; # Publish workstation service
    };
  };
}
