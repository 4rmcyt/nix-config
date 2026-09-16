{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.caddy;
  inherit (config.my.defaults) domain email;
in {
  options.my.caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy with Cloudflare DNS-01";

    headscale.enable = lib.mkEnableOption "Caddy vhost for headscale";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflare_acme_credentials = import ../../../lib/cloudflare-acme-secret.nix "caddy";

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
        hash = "sha256-dQvk6ezY6TQ1J7PjhCXnThF/SqVgPwBO8/RXzHCY+js=";
      };
      globalConfig = ''
        email ${email}
      '';

      # Caddy instead of Traefik: Traefik drops the non-standard Upgrade header
      # required by the Tailscale control protocol.
      virtualHosts."hs.${domain}" = lib.mkIf cfg.headscale.enable {
        extraConfig = ''
          tls {
            dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
            resolvers 1.1.1.1
          }

          reverse_proxy 127.0.0.1:${toString config.services.headscale.port} {
            transport http {
              keepalive off
              compression off
            }
          }
        '';
      };
    };

    systemd.services.caddy.serviceConfig = {
      EnvironmentFile = config.sops.secrets.cloudflare_acme_credentials.path;
      NoNewPrivileges = lib.mkDefault true;
      PrivateTmp = lib.mkDefault true;
      ProtectHome = lib.mkDefault true;
      RestrictSUIDSGID = lib.mkDefault true;
      LockPersonality = lib.mkDefault true;
      RestrictRealtime = lib.mkDefault true;
      SystemCallArchitectures = lib.mkDefault "native";

      # nixpkgs' module leaves this at the full systemd default set; caddy only
      # actually needs the two it requests via AmbientCapabilities.
      CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE" "CAP_NET_ADMIN"];

      ProtectClock = lib.mkDefault true;
      ProtectKernelLogs = lib.mkDefault true;
      ProtectKernelModules = lib.mkDefault true;
      ProtectKernelTunables = lib.mkDefault true;
      ProtectControlGroups = lib.mkDefault true;
      ProtectHostname = lib.mkDefault true;
      RestrictNamespaces = lib.mkDefault true;
      MemoryDenyWriteExecute = lib.mkDefault true;
      # AF_NETLINK kept: ambient CAP_NET_ADMIN implies netlink-level network work.
      RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
      ProtectProc = lib.mkDefault "invisible";
      ProcSubset = lib.mkDefault "pid";
      UMask = lib.mkDefault "0077";
      SystemCallFilter = lib.mkDefault ["@system-service"];
      RemoveIPC = lib.mkDefault true;
      # PrivateUsers deliberately NOT set: breaks binding :443 via
      # AmbientCapabilities=CAP_NET_BIND_SERVICE — confirmed live, "bind: permission denied".
      # No IPAddressDeny/Allow: needs unrestricted outbound (DNS-01 ACME, reverse-proxy upstreams).
    };
  };
}
