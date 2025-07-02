{ config, pkgs, ... }:

{
  networking = {
    hostName = "homeserver";
    
    # Use NextDNS as primary DNS with DNS-over-TLS
    nameservers = [
      "45.90.28.0#nextdns0.dns.nextdns.io"
      "45.90.30.0#nextdns0.dns.nextdns.io"
      "2a07:a8c0::#nextdns0.dns.nextdns.io"
      "2a07:a8c1::#nextdns0.dns.nextdns.io"
    ];

    # Enable systemd-resolved for DNS over TLS
    networkmanager.dns = "systemd-resolved";
    
    # Disable automatic DNS from DHCP to prioritize NextDNS
    dhcpcd.extraConfig = ''
      nooption domain_name_servers
    '';
  };

  # Configure systemd-resolved for NextDNS with enhanced security
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [
      "45.90.28.0#nextdns0.dns.nextdns.io"
      "45.90.30.0#nextdns0.dns.nextdns.io"
    ];
    extraConfig = ''
      # NextDNS configuration with DNS-over-TLS
      DNS=45.90.28.0#nextdns0.dns.nextdns.io 45.90.30.0#nextdns0.dns.nextdns.io
      DNSOverTLS=yes
      
      # Security and performance settings
      DNSSEC=yes
      DNSStubListener=yes
      Cache=yes
      
      # Prevent DNS leaks
      Domains=~.
      ReadEtcHosts=yes
    '';
  };
}