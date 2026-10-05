{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.uaExit;
  socket = "/run/tailscale-ua/tailscaled.sock";
  # Talks to the second tailscaled, e.g. `tailscale-ua status`.
  tailscaleUa = pkgs.writeShellScriptBin "tailscale-ua" ''
    exec ${config.services.tailscale.package}/bin/tailscale --socket=${socket} "$@"
  '';
in {
  options.my.uaExit = {
    enable = lib.mkEnableOption "Tailscale exit node (ua-exit) whose internet goes out via the ClearVPN Ukraine WireGuard netns";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.wg_ua_conf = {
      sopsFile = ../../../secrets/wg-ua.conf;
      format = "binary";
      mode = "0600";
    };

    # Defaults (192.168.15.x / fd93:9701:1d00::) are taken by the `wg` namespace.
    vpnNamespaces.ua = {
      enable = true;
      wireguardConfigFile = config.sops.secrets.wg_ua_conf.path;
      namespaceAddress = "192.168.16.1";
      bridgeAddress = "192.168.16.5";
      namespaceAddressIPv6 = "fd93:9701:1d01::2";
      bridgeAddressIPv6 = "fd93:9701:1d01::1";
    };

    # Second tailscaled, separate node identity/state; the host's own tailscaled is untouched.
    systemd.services.tailscaled-ua = {
      description = "Tailscale exit node via Ukraine VPN (ua-exit)";
      wantedBy = ["multi-user.target"];
      vpnConfinement = {
        enable = true;
        vpnNamespace = "ua";
      };
      path = [pkgs.iptables pkgs.iproute2];
      serviceConfig = {
        # Per-netns sysctls; exit-node traffic is forwarded tailscale0 -> ua0 inside the namespace.
        ExecStartPre = "${pkgs.procps}/bin/sysctl -w net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1";
        ExecStart = "${config.services.tailscale.package}/bin/tailscaled --statedir=/var/lib/tailscale-ua --socket=${socket} --port=0 --tun=tailscale0";
        StateDirectory = "tailscale-ua";
        RuntimeDirectory = "tailscale-ua";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    environment.systemPackages = [tailscaleUa];
  };
}
