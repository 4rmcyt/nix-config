{
  config,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.my.headscale;
  inherit (config.my.defaults) domain;
in {
  options.my.headscale.enable = mkEnableOption "Headscale coordination server + Headplane web UI";

  config = mkIf cfg.enable {
    # Headplane overlay provides pkgs.headplane
    nixpkgs.overlays = [inputs.headplane.overlays.default];

    sops.secrets.headplane_cookie_secret = {
      sopsFile = ../../../secrets/headscale.yaml;
      key = "headplane_cookie_secret";
      owner = config.services.headscale.user;
      inherit (config.services.headscale) group;
      mode = "0400";
    };

    sops.secrets.headplane_agent_preauth_key = {
      sopsFile = ../../../secrets/headscale.yaml;
      key = "headplane_agent_preauth_key";
      owner = config.services.headscale.user;
      inherit (config.services.headscale) group;
      mode = "0400";
    };

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
          nameservers.global = ["1.1.1.1" "1.0.0.1"];
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

    services.headplane = {
      enable = true;
      settings = {
        server = {
          host = "127.0.0.1";
          port = 3050;
          base_url = "https://headplane.${domain}";
          cookie_secret_path = config.sops.secrets.headplane_cookie_secret.path;
          cookie_secure = true;
        };
        headscale = {
          url = "http://127.0.0.1:8765";
          config_path = "/etc/headscale/settings.yaml";
          config_strict = false;
        };
        integration = {
          proc.enabled = true;
          agent = {
            enabled = true;
            pre_authkey_path = config.sops.secrets.headplane_agent_preauth_key.path;
          };
        };
      };
    };

    # Open STUN port for embedded DERP server
    networking.firewall.allowedUDPPorts = [3478];
  };
}
