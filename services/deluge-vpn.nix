{ config, pkgs, lib, ... }:

let
  # Create the scripts as proper Nix derivations
  pia-setup-script = pkgs.writeShellScript "pia-setup.sh" (builtins.readFile ../scripts/pia-setup.sh);
  vpn-routing-script = pkgs.writeShellScript "vpn-routing.sh" (builtins.readFile ../scripts/vpn-routing.sh);
  vpn-cleanup-script = pkgs.writeShellScript "vpn-cleanup.sh" (builtins.readFile ../scripts/vpn-cleanup.sh);
in
{
  # Create deluge user first
  users.users.deluge = {
    isSystemUser = true;
    group = "deluge";
    uid = 993;
    home = "/var/lib/deluge";
    createHome = true;
  };

  users.groups.deluge = {
    gid = 993;
  };

  sops.secrets.pia_username = {
    owner = "deluge";
    group = "deluge";
    mode = "0600";
  };

  sops.secrets.pia_password = {
    owner = "deluge";
    group = "deluge";
    mode = "0600";
  };

  # Service to generate PIA WireGuard config
  systemd.services.pia-wg-setup = {
    description = "Generate PIA WireGuard configuration";
    wantedBy = [ "multi-user.target" ];
    before = [ "wireguard-wg-deluge.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "120s";
      PATH = "${pkgs.curl}/bin:${pkgs.jq}/bin:${pkgs.wireguard-tools}/bin:${pkgs.coreutils}/bin";
    };

    script = ''
      # Get PIA credentials
      PIA_USER=$(cat ${config.sops.secrets.pia_username.path})
      PIA_PASS=$(cat ${config.sops.secrets.pia_password.path})

      # Run the PIA setup script
      ${pia-setup-script} "$PIA_USER" "$PIA_PASS"
    '';
  };

  # WireGuard interface
  networking.wireguard.interfaces.wg-deluge = {
    privateKeyFile = "/var/lib/deluge/pia/private_key";
    listenPort = 51820;
  };

  # VPN routing setup service
  systemd.services.deluge-vpn-routing = {
    description = "Setup VPN routing for Deluge";
    wantedBy = [ "multi-user.target" ];
    after = [ "wireguard-wg-deluge.service" "pia-wg-setup.service" ];
    wants = [ "wireguard-wg-deluge.service" "pia-wg-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "60s";
      PATH = "${pkgs.iproute2}/bin:${pkgs.wireguard-tools}/bin:${pkgs.coreutils}/bin";
    };

    script = "${vpn-routing-script}";
    preStop = "${vpn-cleanup-script}";
  };

  # Deluge daemon service
  systemd.services.deluged = {
    description = "Deluge BitTorrent Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "deluge-vpn-routing.service" ];
    wants = [ "deluge-vpn-routing.service" ];
    serviceConfig = {
      Type = "forking";
      User = "deluge";
      Group = "deluge";
      UMask = "0002";
      ExecStart = "${pkgs.deluge}/bin/deluged -d -c /var/lib/deluge/.config/deluge -l /var/lib/deluge/daemon.log -L info";
      PIDFile = "/var/lib/deluge/.config/deluge/deluged.pid";
      Restart = "on-failure";
      PrivateNetwork = false;
    };
  };

  # Deluge web interface
  systemd.services.deluge-web = {
    description = "Deluge BitTorrent Web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "deluged.service" ];
    wants = [ "deluged.service" ];
    serviceConfig = {
      Type = "forking";
      User = "deluge";
      Group = "deluge";
      ExecStart = "${pkgs.deluge}/bin/deluge-web -d -c /var/lib/deluge/.config/deluge -l /var/lib/deluge/web.log -L info";
      PIDFile = "/var/lib/deluge/.config/deluge/deluge-web.pid";
      Restart = "on-failure";
    };
  };

  # Open firewall for Deluge web interface
  networking.firewall = {
    allowedTCPPorts = [ 8112 ];  # Deluge web interface
    allowedUDPPorts = [ 51820 ]; # WireGuard
  };

  # Ensure deluge config directory exists
  system.activationScripts.deluge-config = ''
    mkdir -p /var/lib/deluge/.config/deluge
    chown deluge:deluge /var/lib/deluge/.config/deluge
    chmod 755 /var/lib/deluge/.config/deluge
  '';
}