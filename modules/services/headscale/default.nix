{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.headscale;
  inherit (config.my.defaults) domain;
in {
  options.my.headscale.enable = mkEnableOption "Headscale coordination server";

  config = mkIf cfg.enable {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8765;
      settings = {
        server_url = "https://head.${domain}";
        log.level = "info";
        logtail.enabled = false;
        dns = {
          magic_dns = true;
          base_domain = "ts.${domain}";
          nameservers.global = ["https://dns.nextdns.io/nextdns0"];
        };
        derp.server = {
          enabled = true;
          region_id = 999;
          region_code = "homelab";
          region_name = "Homelab DERP";
          stun_listen_addr = "0.0.0.0:3478";
        };
      };
    };

    # Open STUN port for embedded DERP server
    networking.firewall.allowedUDPPorts = [3478];
  };
}
