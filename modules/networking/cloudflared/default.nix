# Fully declarative Cloudflare Tunnel via nixpkgs' services.cloudflared module
# (DynamicUser-based, not our own systemd unit). certificateFile is the
# account-level cert.pem (from `cloudflared login`) — required for cloudflared
# to create the public-hostname DNS records itself; without it, routes can
# only be created by hand via the Cloudflare dashboard/API.
#
# The tunnel UUID has to be a literal Nix attribute name (services.cloudflared
# .tunnels.<uuid>), so it can't come from a sops secret — it's not sensitive
# on its own (it's the same UUID publicly visible in every
# <uuid>.cfargotunnel.com CNAME target once DNS is set up).
{
  config,
  lib,
  ...
}: let
  inherit (config.my.defaults) domain;
  tunnelId = "57a75d0b-ba3c-4b13-9e45-8854e13fc0fb";

  hostnames = ["hass" "livesync" "cal" "ntfy" "jobko" "idm"];

  mkIngress = name: {
    "${name}.${domain}" = {
      service = "https://localhost:443";
      originRequest = {
        originServerName = "${name}.${domain}";
        noTLSVerify = true;
      };
    };
  };
in {
  sops.secrets = {
    cloudflare_tunnel_credentials = {
      sopsFile = ../../../secrets/cloudflare_tunnel_credentials.bin;
      key = "data";
      format = "binary";
    };

    cloudflare_tunnel_cert = {
      sopsFile = ../../../secrets/cloudflare_tunnel_cert.pem;
      key = "data";
      format = "binary";
    };
  };

  services.cloudflared = {
    enable = true;
    certificateFile = config.sops.secrets.cloudflare_tunnel_cert.path;

    tunnels.${tunnelId} = {
      credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;
      default = "http_status:404";

      originRequest = {
        connectTimeout = "30s";
        tcpKeepAlive = "30s";
        keepAliveTimeout = "90s";
        keepAliveConnections = 100;
        noHappyEyeballs = false;
      };

      ingress = builtins.foldl' (acc: name: acc // mkIngress name) {} hostnames;
    };
  };

  # nixpkgs' cloudflared module already sets DynamicUser=yes,
  # ProtectSystem=strict, NoNewPrivileges=yes with AmbientCapabilities empty
  # (verified via `systemctl show cloudflared-tunnel-<uuid>.service`) — it
  # doesn't request any capability, it only makes outbound QUIC/HTTP2
  # connections to Cloudflare's edge.
  systemd.services."cloudflared-tunnel-57a75d0b-ba3c-4b13-9e45-8854e13fc0fb".serviceConfig = {
    CapabilityBoundingSet = lib.mkDefault [];
    RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX"];
    ProtectClock = lib.mkDefault true;
    ProtectKernelLogs = lib.mkDefault true;
    ProtectKernelModules = lib.mkDefault true;
    ProtectKernelTunables = lib.mkDefault true;
    ProtectControlGroups = lib.mkDefault true;
    ProtectHostname = lib.mkDefault true;
    RestrictNamespaces = lib.mkDefault true;
    RestrictSUIDSGID = lib.mkDefault true;
    LockPersonality = lib.mkDefault true;
    RestrictRealtime = lib.mkDefault true;
    ProtectProc = lib.mkDefault "invisible";
    ProcSubset = lib.mkDefault "pid";
    UMask = lib.mkDefault "0077";
    RemoveIPC = lib.mkDefault true;
    # Deliberately NOT setting SystemCallFilter, MemoryDenyWriteExecute, or
    # PrivateUsers: cloudflared is Go, same runtime family that got
    # alloy.service killed (SIGSYS) via these exact kill-on-violation
    # directives on gcp-relay — and this tunnel is the single ingress path
    # for hass/livesync/cal/ntfy/jobko/idm, including Kanidm SSO. Not the
    # place to find out the hard way.
  };
}
