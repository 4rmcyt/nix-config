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
{config, ...}: let
  inherit (config.my.defaults) domain;
  tunnelId = "f7876e26-87a8-4bdd-9798-3986b0f7cebc";

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
      key = "credentials";
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
}
