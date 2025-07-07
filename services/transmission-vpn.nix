# /etc/nixos/services/transmission-vpn.nix

{ config, pkgs, inputs, ... }:

let
  # This script is automatically executed by the nix-pia-vpn module whenever
  # PIA assigns a new forwarded port. The port number is passed as the first
  # argument ($1).
  update-transmission-port-script = pkgs.writeShellScript "update-transmission-port.sh" ''
    #!${pkgs.runtimeShell}
    
    # The new port provided by PIA
    PORT="$1"

    # Log the event to the system journal for easy debugging.
    # You can view these logs with: journalctl -t update-transmission-port
    echo "Received new PIA port: $PORT. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t update-transmission-port

    # Use the transmission-remote tool to instantly update the running daemon.
    # This is more efficient than restarting the whole service.
    # We run this as the 'transmission' user.
    ${pkgs.sudo}/bin/sudo -u transmission ${pkgs.transmission}/bin/transmission-remote --peerport "$PORT"
  '';

in
{
  # == 1. PIA VPN Configuration ==
  imports = [
    inputs.nix-pia-vpn.nixosModules.default
  ];

  services.pia-vpn = {
    enable = true;
    user = "transmission";
    sopsFile = ../secrets/pia_credentials.txt;

    # --- CORRECTED OPTION ---
    # The option to specify a server location is 'region'.
    region = "ca_ontario";

    onPortForward = update-transmission-port-script;
  };

  # == 2. Transmission Service Configuration ==
  services.transmission = {
    enable = true;
    user = "transmission";
    group = "transmission";
    rpc-bind-address = "127.0.0.1";
    download-dir = "/var/lib/transmission/downloads";
    peer-port = 51413;
  };

  # == 3. User and Firewall Configuration ==
  users.users.transmission = {
    isSystemUser = true;
    group = "transmission";
    home = "/var/lib/transmission";
  };
  users.groups.transmission = {};
  networking.firewall.allowedTCPPorts = [ 9091 ];
}