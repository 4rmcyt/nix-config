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

    # nixpkgs' crowdsec-firewall-bouncer module already sets
    # CapabilityBoundingSet=cap_net_admin only (no cap_net_raw — verified via
    # `systemctl show crowdsec-firewall-bouncer.service`, don't assume it
    # needs more), RestrictAddressFamilies=AF_INET/AF_INET6/AF_NETLINK/AF_UNIX,
    # a curated SystemCallFilter, and DynamicUser=yes — do not touch those.
    # These are just the additive sandboxing toggles the module leaves
    # unset. No IPAddressDeny/Allow: it talks to the LAPI over Tailscale
    # (homeserver, not local), so it needs outbound beyond just localhost.
    systemd.services.crowdsec-firewall-bouncer.serviceConfig = {
      ProtectClock = lib.mkDefault true;
      ProtectKernelLogs = lib.mkDefault true;
      ProtectKernelModules = lib.mkDefault true;
      ProtectKernelTunables = lib.mkDefault true;
      ProtectHostname = lib.mkDefault true;
      RestrictNamespaces = lib.mkDefault true;
      MemoryDenyWriteExecute = lib.mkDefault true;
      ProtectProc = lib.mkDefault "invisible";
      ProcSubset = lib.mkDefault "pid";
      UMask = lib.mkDefault "0077";
      RemoveIPC = lib.mkDefault true;
      # PrivateUsers deliberately NOT set: it breaks CAP_NET_ADMIN's netlink
      # access for nftables — the kernel's netlink permission check doesn't
      # carry over once the service is in its own user namespace. Confirmed
      # live: "netlink receive: operation not permitted" on deploy with
      # PrivateUsers=true.
      # ProtectControlGroups left alone — the bouncer's nftables backend
      # sometimes needs cgroup-based matching depending on ruleset; not
      # worth the risk to verify blind.
    };
  };
}
