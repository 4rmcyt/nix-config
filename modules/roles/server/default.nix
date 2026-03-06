{
  config,
  lib,
  ...
}: {
  options.roles.server = {
    enable = lib.mkEnableOption "server role with common server configurations";
  };

  config = lib.mkIf config.roles.server.enable {
    # Automatic upgrades are generally enabled in modules/base/auto_upgrade.
    # The server role explicitly disables them, forcing manual updates for stability.
    system.autoUpgrade.enable = lib.mkForce false;

    # Server-optimized settings
    services = {
      # SSH configuration for servers
      openssh = {
        enable = lib.mkDefault true;
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          PermitRootLogin = lib.mkDefault "no";
          X11Forwarding = lib.mkDefault false;
          UseDNS = false;
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
