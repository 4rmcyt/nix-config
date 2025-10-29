{
  config,
  lib,
  ...
}: {
  options.roles.server = {
    enable = lib.mkEnableOption "server role with common server configurations";
  };

  config = lib.mkIf config.roles.server.enable {
    # Server-optimized settings
    services = {
      # Automatic updates for servers
      automatic-upgrades = {
        enable = lib.mkDefault false; # Servers should update manually for stability
      };

      # SSH configuration for servers
      openssh = {
        enable = lib.mkDefault true;
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          PermitRootLogin = lib.mkDefault "no";
          X11Forwarding = lib.mkDefault false;
        };
      };

      # Time synchronization
      timesyncd.enable = lib.mkDefault true;
    };

    # Server networking defaults
    networking = {
      firewall = {
        enable = lib.mkDefault true;
        allowPing = lib.mkDefault true;
      };
    };

    # No GUI packages on servers
    environment.noXlibs = lib.mkDefault true;

    # Server-specific system settings
    boot = {
      # Clean tmp on boot
      tmp.cleanOnBoot = lib.mkDefault true;
    };

    # Minimal system packages for servers
    environment.systemPackages = lib.mkDefault [];
  };
}
