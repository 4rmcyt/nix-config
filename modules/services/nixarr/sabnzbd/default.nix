{
  pkgs,
  lib,
  ...
}: {
  users.users.sabnzbd = {
    extraGroups = [
      "users"
      "media"
    ];
  };

  services.sabnzbd = {
    enable = true;
    user = "sabnzbd";
    group = "sabnzbd";
  };

  # Override SABnzbd service to run in VPN namespace
  systemd.services.sabnzbd = {
    after = ["wg.service"];
    requires = ["wg.service"];

    serviceConfig = {
      # Clear BindPaths from parent nixarr config - they conflict with NetworkNamespacePath
      BindPaths = lib.mkForce [];

      # VPN namespace configuration
      NetworkNamespacePath = "/run/netns/wg";
      BindReadOnlyPaths = lib.mkForce [
        "/etc/netns/wg/resolv.conf:/etc/resolv.conf:norbind"
      ];

      # Essential overrides for namespace compatibility
      RestrictNamespaces = lib.mkForce false;
      PrivateNetwork = lib.mkForce false;
      PrivateUsers = lib.mkForce false;

      # Service management
      Restart = lib.mkForce "always";
      RestartSec = "10s";
    };
  };

  # Socket for SABnzbd proxy (allows access from host network on port 8082)
  systemd.sockets.proxy-to-sabnzbd = {
    description = "Socket for SABnzbd proxy";
    wantedBy = ["sockets.target"];
    requires = ["sabnzbd.service"];
    socketConfig = {
      ListenStream = "8082"; # Listen on port 8082 on host
    };
  };

  # Proxy service to connect to SABnzbd in VPN namespace (on port 8080)
  systemd.services.proxy-to-sabnzbd = {
    description = "Proxy to SABnzbd in VPN namespace";
    after = ["sabnzbd.service"];
    requires = ["sabnzbd.service"];

    serviceConfig = {
      # Enter VPN namespace and proxy to SABnzbd on port 8080
      ExecStart = "${pkgs.util-linux}/bin/nsenter --net=/run/netns/wg ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8080";
    };
  };

  # Create additional directories
  systemd.tmpfiles.rules = [
    "d /data/media/.state/nixarr/sabnzbd 775 sabnzbd sabnzbd -"
    "d /data/Downloads/usenet 775 sabnzbd media -"
    "d /data/Downloads/usenet/incomplete 775 sabnzbd media -"
    "d /data/Downloads/usenet/complete 775 sabnzbd media -"
  ];
}
