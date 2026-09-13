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

      # https://hs.<domain> → headscale :8080 (Tailscale control protocol)
      #
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

      # nixpkgs' caddy module leaves CapabilityBoundingSet at the systemd
      # default (the full ~40-capability set: cap_sys_admin, cap_sys_module,
      # cap_sys_boot, ...). It only actually needs the two it already
      # requests via AmbientCapabilities (verified via `systemctl show
      # caddy.service -p AmbientCapabilities`, do not change without
      # rechecking that first).
      CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE" "CAP_NET_ADMIN"];

      ProtectClock = lib.mkDefault true;
      ProtectKernelLogs = lib.mkDefault true;
      ProtectKernelModules = lib.mkDefault true;
      ProtectKernelTunables = lib.mkDefault true;
      ProtectControlGroups = lib.mkDefault true;
      ProtectHostname = lib.mkDefault true;
      RestrictNamespaces = lib.mkDefault true;
      MemoryDenyWriteExecute = lib.mkDefault true;
      # AF_NETLINK kept: ambient CAP_NET_ADMIN implies caddy (or a plugin)
      # does netlink-level network work, not just listen()/connect().
      RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
      ProtectProc = lib.mkDefault "invisible";
      ProcSubset = lib.mkDefault "pid";
      UMask = lib.mkDefault "0077";
      SystemCallFilter = lib.mkDefault ["@system-service"];
      RemoveIPC = lib.mkDefault true;
      # PrivateUsers deliberately NOT set: it breaks binding :443 via
      # AmbientCapabilities=CAP_NET_BIND_SERVICE — the kernel's privileged-
      # port check doesn't recognize the capability once the service is in
      # its own user namespace. Confirmed live: "bind: permission denied"
      # on deploy with PrivateUsers=true.
      # No IPAddressDeny/Allow — caddy needs unrestricted outbound (DNS-01
      # ACME to Cloudflare's API, arbitrary reverse-proxy upstreams).
    };
  };
}
