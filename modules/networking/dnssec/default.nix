{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.networking.dnssec;
  inherit (config.networking) hostName;
  inherit (cfg) profileId;
  nextdnsHost = "${hostName}-${profileId}.dns.nextdns.io";
in {
  options.networking.dnssec = {
    enable = mkEnableOption "DNSSEC/NextDNS configuration";
    profileId = mkOption {
      type = types.str;
      description = "NextDNS profile ID (e.g., nextdns0)";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      nameservers = [
        "45.90.28.0#${nextdnsHost}"
        "45.90.30.0#${nextdnsHost}"
      ];
      networkmanager.dns = mkForce "none";
    };

    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNSSEC = "allow-downgrade";
        Domains = ["~."];
        FallbackDNS = [
          "45.90.28.0#${nextdnsHost}"
          "2a07:a8c0::#${nextdnsHost}"
          "45.90.30.0#${nextdnsHost}"
          "2a07:a8c1::#${nextdnsHost}"
        ];
        DNSOverTLS = "true";
      };
    };

    # NegativeTrustAnchors was removed from resolved.conf in systemd 250+
    # The replacement is /etc/dnssec-trust-anchors.d/*.negative
    environment.etc."dnssec-trust-anchors.d/local.negative".text = ''
      example.com
    '';
  };
}
