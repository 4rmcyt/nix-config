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
  # This section leverages the nix-pia-vpn flake to manage the connection.
  imports = [
    # Import the module from the flake input.
    inputs.nix-pia-vpn.nixosModules.default
  ];

  # Enable the PIA VPN service.
  services.pia-vpn = {
    enable = true;
    # The user that the Transmission service will run as.
    # This user will be automatically added to the 'pia-vpn' group,
    # ensuring all its traffic is routed through the VPN.
    user = "transmission";

    # --- CORRECTED OPTION ---
    # Point directly to your SOPS-encrypted credentials file.
    # The module handles decryption automatically.
    # The path is relative to this .nix file.
    sopsFile = ../secrets/pia_credentials.txt;

    # Specify your desired server location.
    # A list of locations can be found here: https://github.com/rcambrj/nix-pia-vpn
    location = "ca_ontario";

    # Hook to automatically update Transmission's port.
    onPortForward = update-transmission-port-script;
  };

  # The sops.secrets block for pia_credentials is no longer needed here,
  # as the nix-pia-vpn module manages the secret itself via the sopsFile option.


  # == 2. Transmission Service Configuration ==
  services.transmission = {
    enable = true;
    # Run the service as the 'transmission' user.
    user = "transmission";
    group = "transmission";

    # For security, only allow access to the Web UI from the local machine.
    rpc-bind-address = "127.0.0.1";

    # Set the default download directory.
    download-dir = "/var/lib/transmission/downloads";

    # Initial port setting. This will be immediately updated by the VPN hook.
    peer-port = 51413;
  };

  # Create the 'transmission' user and group.
  users.users.transmission = {
    isSystemUser = true;
    group = "transmission";
    home = "/var/lib/transmission";
  };
  users.groups.transmission = {};


  # == 3. Firewall Configuration ==
  # Allows access to the Transmission Web UI (port 9091) from your local network.
  networking.firewall.allowedTCPPorts = [ 9091 ];
}
