{
  config,
  lib,
  ...
}: let
  cfg = config.my.crowdsecBouncer;
in {
  options.my.crowdsecBouncer = {
    enable = lib.mkEnableOption "CrowdSec nftables bouncer (remote LAPI)";

    lapiUrl = lib.mkOption {
      type = lib.types.str;
      description = "CrowdSec LAPI URL (remote host over Tailscale).";
      example = "http://100.64.0.3:8080";
    };

    secretsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/crowdsec.yaml;
      description = "Sops file containing crowdsec_bouncer_key_nftables.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.crowdsec_bouncer_key_nftables = {
      sopsFile = cfg.secretsFile;
      owner = "root";
      mode = "0400";
    };

    services.crowdsec-firewall-bouncer = {
      enable = true;
      secrets.apiKeyPath = config.sops.secrets.crowdsec_bouncer_key_nftables.path;
      settings = {
        mode = "nftables";
        api_url = cfg.lapiUrl;
      };
    };

    systemd.services.crowdsec-firewall-bouncer = {
      after = ["nftables.service" "tailscaled.service"];
      requires = ["tailscaled.service"];
    };

    networking.nftables.enable = true;
  };
}
