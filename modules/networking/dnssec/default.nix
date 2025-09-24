_: {
  dhcpcd.extraConfig = "nohook resolv.conf";
  networkmanager.dns = "none";

  networking.nameservers = [
    "45.90.28.0#Desktop-nextdns0.dns.nextdns.io"
    "45.90.30.0#Desktop-nextdns0.dns.nextdns.io"
  ];

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [
      "45.90.28.0#Desktop-nextdns0.dns.nextdns.io"
      "2a07:a8c0::#nextdns0.dns.nextdns.io"
      "45.90.30.0#Desktop-nextdns0.dns.nextdns.io"
      "2a07:a8c1::#nextdns0.dns.nextdns.io"
    ];
    dnsovertls = "true";
  };
}
