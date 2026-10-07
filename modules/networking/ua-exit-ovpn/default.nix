{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.uaExitOvpn;
  ns = "uao";
  socket = "/run/tailscale-uao/tailscaled.sock";
  # Talks to the third tailscaled, e.g. `tailscale-uao status`.
  tailscaleUao = pkgs.writeShellScriptBin "tailscale-uao" ''
    exec ${config.services.tailscale.package}/bin/tailscale --socket=${socket} "$@"
  '';
in {
  options.my.uaExitOvpn = {
    enable = lib.mkEnableOption "Tailscale exit node (ua-exit-ovpn) whose internet goes out via the ClearVPN Ukraine OpenVPN netns";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      ua_ovpn_conf = {
        sopsFile = ../../../secrets/wg-ua-ovpn.conf;
        format = "binary";
        mode = "0600";
      };
      ua_ovpn_username = {
        sopsFile = ../../../secrets/ua-ovpn-auth.yaml;
        key = "username";
      };
      ua_ovpn_password = {
        sopsFile = ../../../secrets/ua-ovpn-auth.yaml;
        key = "password";
      };
    };
    # auth-user-pass wants a two-line file: username, password.
    sops.templates."ua-ovpn-auth".content = ''
      ${config.sops.placeholder.ua_ovpn_username}
      ${config.sops.placeholder.ua_ovpn_password}
    '';

    # Empty netns (lo only): the tun is the sole way out, so nothing leaks if OpenVPN drops.
    systemd.services."netns-${ns}" = {
      description = "Network namespace ${ns} for ua-exit-ovpn";
      before = ["openvpn-ua-ovpn.service"];
      path = [pkgs.iproute2];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = [
          "${pkgs.iproute2}/bin/ip netns add ${ns}"
          "${pkgs.iproute2}/bin/ip -n ${ns} link set lo up"
        ];
        ExecStop = "${pkgs.iproute2}/bin/ip netns del ${ns}";
      };
    };

    # Socket stays in the host netns; the up script moves the tun into the netns and configures it there.
    services.openvpn.servers.ua-ovpn = {
      # DCO devices can't be moved across netns; plain tun can.
      config = ''
        config ${config.sops.secrets.ua_ovpn_conf.path}
        ifconfig-noexec
        route-noexec
        disable-dco
      '';
      authUserPass = config.sops.templates."ua-ovpn-auth".path;
      up = ''
        ip link set dev "$dev" netns ${ns}
        ip -n ${ns} link set dev "$dev" mtu "$tun_mtu" up
        if [ -n "''${ifconfig_remote:-}" ]; then
          ip -n ${ns} addr add "$ifconfig_local" peer "$ifconfig_remote" dev "$dev"
        else
          ip -n ${ns} addr add "$ifconfig_local/$ifconfig_netmask" dev "$dev"
        fi
        ip -n ${ns} route replace default dev "$dev"
        mkdir -p /etc/netns/${ns}
        printf 'nameserver %s\n' ''${nameserver:-1.1.1.1} > /etc/netns/${ns}/resolv.conf
      '';
    };
    systemd.services.openvpn-ua-ovpn = {
      requires = ["netns-${ns}.service"];
      after = ["netns-${ns}.service"];
    };

    # Third tailscaled, separate node identity/state; host and ua-exit tailscaleds are untouched.
    systemd.services.tailscaled-uao = {
      description = "Tailscale exit node via Ukraine OpenVPN (ua-exit-ovpn)";
      wantedBy = ["multi-user.target"];
      requires = ["netns-${ns}.service"];
      after = ["netns-${ns}.service" "openvpn-ua-ovpn.service"];
      wants = ["openvpn-ua-ovpn.service"];
      path = [pkgs.iptables pkgs.iproute2];
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/${ns}";
        # systemd doesn't apply /etc/netns like `ip netns exec`; nscd would resolve via the host netns.
        BindReadOnlyPaths = ["/etc/netns/${ns}/resolv.conf:/etc/resolv.conf"];
        InaccessiblePaths = ["-/run/nscd"];
        # Per-netns sysctls; exit-node traffic is forwarded tailscale0 -> tun inside the namespace.
        ExecStartPre = "${pkgs.procps}/bin/sysctl -w net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1";
        ExecStart = "${config.services.tailscale.package}/bin/tailscaled --statedir=/var/lib/tailscale-uao --socket=${socket} --port=0 --tun=tailscale0";
        StateDirectory = "tailscale-uao";
        RuntimeDirectory = "tailscale-uao";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    environment.systemPackages = [tailscaleUao];
  };
}
