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

  # Define the sops secret for the PIA credentials.
  # This makes the decrypted file available at a predictable path in /run/secrets.
  sops.secrets.pia_credentials = {
    # The user/group that will run the VPN service needs read access.
    owner = config.users.users.transmission.name;
    group = config.users.groups.transmission.name;
  };

  # Enable the PIA VPN service.
  services.pia-vpn = {
    enable = true;

    # --- CORRECTED STRUCTURE ---
    # The module likely expects all configuration to be nested under a 'settings' attribute.
    settings = {
      # The user that the Transmission service will run as.
      user = "transmission";

      # The option to specify a server location.
      region = "ca_ontario";

      # Provide the path to the credentials file decrypted by the main sops module.
      credentialsFile = config.sops.secrets.pia_credentials.path;

      # Port forwarding settings are likely configured in an attribute set.
      portForward = {
        enable = true;
        script = update-transmission-port-script;
      };
    };
  };


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
