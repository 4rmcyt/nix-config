# CrowdSec nftables bouncer — connects to a remote LAPI over Tailscale.
# No local CrowdSec agent is run on this host.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.crowdsecBouncer;
in
{
  options.my.crowdsecBouncer = {
    enable = lib.mkEnableOption "CrowdSec nftables bouncer (remote LAPI)";

    lapiUrl = lib.mkOption {
      type = lib.types.str;
      description = "CrowdSec LAPI URL (remote host over Tailscale).";
      example = "http://100.64.0.3:8088";
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

    systemd.services.crowdsec-firewall-bouncer-key = {
      description = "Write CrowdSec nftables bouncer API key to /run";
      before = [ "crowdsec-firewall-bouncer.service" ];
      wantedBy = [ "crowdsec-firewall-bouncer.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "crowdsec-bouncer-key" ''
          install -d -m 0700 /run/crowdsec-bouncer
          install -m 0600 ${config.sops.secrets.crowdsec_bouncer_key_nftables.path} /run/crowdsec-bouncer/api_key
        '';
      };
    };

    services.crowdsec-firewall-bouncer = {
      enable = true;
      settings = {
        mode = "nftables";
        api_key_path = "/run/crowdsec-bouncer/api_key";
        api_url = cfg.lapiUrl;
      };
    };

    systemd.services.crowdsec-firewall-bouncer = {
      after = [
        "nftables.service"
        "tailscaled.service"
      ];
      requires = [ "tailscaled.service" ];
    };

    networking.nftables.enable = true;
  };
}
