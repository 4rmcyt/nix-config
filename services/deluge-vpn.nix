{ config, pkgs,... }:

let
  vpnNamespace = "wg-deluge";
in
{
  # PIA WireGuard configuration
  sops.secrets.wireguard_deluge = { };

  systemd.services = {
    "netns-${vpnNamespace}" = {
      description = "Network namespace for Deluge VPN";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip netns add ${vpnNamespace}";
        ExecStop = "${pkgs.iproute2}/bin/ip netns del ${vpnNamespace}";
      };
    };

    "wireguard-${vpnNamespace}" = {
      description = "WireGuard interface for Deluge with PIA";
      after = [ "netns-${vpnNamespace}.service" ];
      requires = [ "netns-${vpnNamespace}.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "start-wg-deluge" ''
          # Create WireGuard interface in namespace
          ${pkgs.iproute2}/bin/ip netns exec ${vpnNamespace} ${pkgs.wireguard-tools}/bin/wg-quick up ${config.sops.secrets.wireguard_deluge.path}
        '';
        ExecStop = pkgs.writeShellScript "stop-wg-deluge" ''
          ${pkgs.iproute2}/bin/ip netns exec ${vpnNamespace} ${pkgs.wireguard-tools}/bin/wg-quick down wg0 || true
        '';
      };
    };
  };

  services.deluge = {
    enable = true;
    web.enable = true;
    web.port = 8112;
    declarative = true;
    daemon.serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/${vpnNamespace}";
      After = "wireguard-${vpnNamespace}.service";
      Requires = "wireguard-${vpnNamespace}.service";
    };
    web.serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/${vpnNamespace}";
      After = "wireguard-${vpnNamespace}.service";
      Requires = "wireguard-${vpnNamespace}.service";
    };
    config = {
      allow_remote = true;
      download_location = "/home/zeev/downloads";
      torrentfiles_location = "/home/zeev/downloads/torrents";
    };
  };

  # Create download directories
  systemd.tmpfiles.rules = [
    "d /home/zeev/downloads 0755 zeev users -"
    "d /home/zeev/downloads/torrents 0755 zeev users -"
  ];
}