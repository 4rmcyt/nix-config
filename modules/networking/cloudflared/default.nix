# certificateFile is required for cloudflared to create public-hostname DNS records
# itself; without it routes can only be created by hand via the Cloudflare dashboard.
# The tunnel UUID can't come from a sops secret (it's a literal Nix attribute name),
# but it isn't sensitive — it's publicly visible in the <uuid>.cfargotunnel.com CNAME.
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

  # nixpkgs' module already sets DynamicUser/ProtectSystem=strict/NoNewPrivileges;
  # it requests no capability, only outbound QUIC/HTTP2 to Cloudflare's edge.
  systemd.services."cloudflared-tunnel-57a75d0b-ba3c-4b13-9e45-8854e13fc0fb".serviceConfig = {
    CapabilityBoundingSet = lib.mkForce "";
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
    # Deliberately NOT setting SystemCallFilter/MemoryDenyWriteExecute/PrivateUsers:
    # cloudflared is Go, same runtime family that got alloy.service killed on
    # gcp-relay, and this tunnel is the single ingress path for Kanidm SSO.
  };
}
