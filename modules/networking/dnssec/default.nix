{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.networking.dnssec;
  inherit (config.networking) hostName;
  inherit (cfg) profileId;
  nextdnsHost = "${hostName}-${profileId}.dns.nextdns.io";
in
{
  options.networking.dnssec = {
    enable = mkEnableOption "DNSSEC/NextDNS configuration";
    profileId = mkOption {
      type = types.str;
      description = "NextDNS profile ID (e.g., 2bffa2)";
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
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [
        "45.90.28.0#${nextdnsHost}"
        "2a07:a8c0::#${nextdnsHost}"
        "45.90.30.0#${nextdnsHost}"
        "2a07:a8c1::#${nextdnsHost}"
      ];
      dnsovertls = "true";
    };
  };
}
