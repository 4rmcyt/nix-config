{ config, pkgs, ... }:

{
  networking = {
    hostName = "homeserver";
    
    # Use NextDNS as primary DNS
    nameservers = [
      "45.90.28.0#nextdns0.dns.nextdns.io"
      "45.90.30.0#nextdns0.dns.nextdns.io"
      "2a07:a8c0::#nextdns0.dns.nextdns.io"
      "2a07:a8c1::#nextdns0.dns.nextdns.io"
    ];

    # Enable systemd-resolved for DNS over TLS
    networkmanager.dns = "systemd-resolved";
  };

  # Configure systemd-resolved for NextDNS
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [
      "45.90.28.0#nextdns0.dns.nextdns.io"
      "45.90.30.0#nextdns0.dns.nextdns.io"
    ];
    extraConfig = ''
      DNS=45.90.28.0#nextdns0.dns.nextdns.io 45.90.30.0#nextdns0.dns.nextdns.io
      DNSOverTLS=yes
    '';
  };
}