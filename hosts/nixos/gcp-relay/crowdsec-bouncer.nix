# CrowdSec nftables bouncer — connects to a remote LAPI over Headscale.
# No local CrowdSec agent is run on this host.
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
      description = "CrowdSec LAPI URL (remote host over headscale).";
      example = "http://<homeserver-tailnet-ip>:8088";
    };

    secretsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/crowdsec-gcp.yaml;
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
      registerBouncer.enable = false;
      secrets.apiKeyPath = config.sops.secrets.crowdsec_bouncer_key_nftables.path;
      settings = {
        mode = "nftables";
        api_url = cfg.lapiUrl;
      };
    };

    systemd.services.crowdsec-firewall-bouncer = {
      after = ["nftables.service" "tailscale-autoconnect.service"];
      requires = ["tailscale-autoconnect.service"];
    };

    # nixpkgs crowdsec module generates an empty crowdsec.service unit even when
    # services.crowdsec.enable = false — mask it to silence the systemd warning.
    systemd.units."crowdsec.service".enable = lib.mkForce false;

    networking.nftables.enable = true;
  };
}
