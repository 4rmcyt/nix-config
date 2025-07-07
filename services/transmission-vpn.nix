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

  # This creates a credentials file in the format required by nix-pia-vpn
  # by combining your existing sops secrets for username and password.
  pia-credentials-file = pkgs.writeText "pia-credentials" ''
    PIA_USER=$(cat ${config.sops.secrets.pia_username.path})
    PIA_PASS=$(cat ${config.sops.secrets.pia_password.path})
  '';

in
{
  # == 1. PIA VPN Configuration ==
  # This section leverages the nix-pia-vpn flake to manage the connection.
  imports = [
    # Import the module from the flake input.
    # Make sure you have 'nix-pia-vpn' defined in your flake.nix inputs.
    inputs.nix-pia-vpn.nixosModules.default
  ];

  # Enable the PIA VPN service.
  services.pia-vpn = {
    enable = true;
    # The user that the Transmission service will run as.
    # This user will be automatically added to the 'pia-vpn' group,
    # ensuring all its traffic is routed through the VPN.
    user = "transmission";

    # Point to the credentials file we just generated declaratively.
    credentialsFile = pia-credentials-file;

    # Specify your desired server location.
    # A list of locations can be found here: https://github.com/rcambrj/nix-pia-vpn
    location = "ca_ontario";

    # Hook to automatically update Transmission's port.
    onPortForward = update-transmission-port-script;
  };

  # Define permissions for your existing SOPS secrets.
  # This ensures the 'transmission' user can read them to create the credentials file.
  sops.secrets.pia_username = {
    owner = config.services.pia-vpn.user;
    group = config.users.users.transmission.group;
  };
  sops.secrets.pia_password = {
    owner = config.services.pia-vpn.user;
    group = config.users.users.transmission.group;
  };


  # == 2. Transmission Service Configuration ==
  services.transmission = {
    enable = true;
    # Run the service as the 'transmission' user. Because this user is in the
    # 'pia-vpn' group, its traffic is automatically firewalled and routed.
    user = "transmission";
    group = "transmission";

    # For security, only allow access to the Web UI from the local machine.
    # Use a reverse proxy (like Caddy or Nginx) to expose it securely.
    rpc-bind-address = "127.0.0.1";

    # Set the default download directory.
    download-dir = "/var/lib/transmission/downloads";

    # Initial port setting. This will be immediately updated by the VPN hook
    # once a connection is established.
    peer-port = 51413; # Default, will be changed by hook.
  };

  # Create the 'transmission' user and group.
  users.users.transmission = {
    isSystemUser = true;
    group = "transmission";
    home = "/var/lib/transmission"; # Home dir for config files.
  };
  users.groups.transmission = {};


  # == 3. Firewall Configuration ==
  # This allows you to access the Transmission Web UI (port 9091)
  # from other devices on your local network.
  # NOTE: This does NOT expose the port to the internet.
  networking.firewall.allowedTCPPorts = [ 9091 ];
}
