{ config, pkgs, ... }:
{
  # User security configuration
  users = {
    # Disable default user creation
    mutableUsers = false; # Force declarative user management

    # Default user settings
    defaultUserShell = pkgs.zsh;

    # Group definitions
    groups = {
      backup = {
        gid = 995;
      };
      services = {
        gid = 994;
      };
      monitoring = {
        gid = 993;
      };
    };

    users = {
      # System users for services
      backup = {
        isSystemUser = true;
        group = "backup";
        home = "/var/lib/backup";
        createHome = true;
        uid = 995;
      };

      monitoring = {
        isSystemUser = true;
        group = "monitoring";
        home = "/var/lib/monitoring";
        createHome = true;
        uid = 993;
      };

      # Regular users
      zeev = {
        isNormalUser = true;
        description = "Zeev";
        uid = 1000;

        # Minimal group membership for security
        extraGroups = [
          "wheel" # sudo access
          "networkmanager" # network management only
          # Remove unnecessary groups like docker, libvirtd, etc.
        ];

        # SSH key only authentication
        openssh.authorizedKeys.keys = [
          # Define your SSH public keys here
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx zeev@workstation"
        ];

        # Security: no password login
        hashedPassword = null;
        password = null;

        shell = pkgs.zsh;
        home = "/home/zeev";
        createHome = true;
        homeMode = "750"; # Restrictive home directory
      };

      # Disable root login completely
      root = {
        hashedPassword = "!"; # Locked
        openssh.authorizedKeys.keys = [ ]; # No SSH keys
      };
    };
  };

  # User security limits
  security.pam.loginLimits = [
    # Per-user limits
    {
      domain = "zeev";
      type = "soft";
      item = "nofile";
      value = "4096";
    }
    {
      domain = "zeev";
      type = "hard";
      item = "nofile";
      value = "8192";
    }
    {
      domain = "zeev";
      type = "soft";
      item = "nproc";
      value = "1024";
    }
    {
      domain = "zeev";
      type = "hard";
      item = "nproc";
      value = "2048";
    }

    # System user limits
    {
      domain = "backup";
      type = "soft";
      item = "nofile";
      value = "2048";
    }
    {
      domain = "backup";
      type = "hard";
      item = "nofile";
      value = "4096";
    }
  ];
}
