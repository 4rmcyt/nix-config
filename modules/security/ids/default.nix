{ config, pkgs, ... }:
{
  # File integrity monitoring with AIDE
  services.aide = {
    enable = true;

    config = ''
      # Database and log locations
      database=file:/var/lib/aide/aide.db
      database_out=file:/var/lib/aide/aide.db.new
      gzip_dbout=yes

      # Report settings
      verbose=5
      report_url=stdout

      # File selection rules
      /bin     NORMAL
      /sbin    NORMAL
      /lib     NORMAL
      /lib64   NORMAL
      /opt     NORMAL
      /usr     NORMAL
      /etc     CONFIGS

      # System directories
      /root/\..* NORMAL
      /root    CONFIGS

      # Critical system files
      /etc/passwd    CRITICAL
      /etc/shadow    CRITICAL
      /etc/group     CRITICAL
      /etc/sudoers   CRITICAL
      /etc/ssh/      CRITICAL

      # NixOS specific
      /nix/store     READONLY
      /etc/nixos     CONFIGS

      # Exclude temporary and volatile areas
      !/tmp
      !/var/tmp
      !/var/log
      !/var/cache
      !/var/run
      !/proc
      !/sys
      !/dev

      # Custom rules
      NORMAL = p+i+n+u+g+s+m+c+acl+selinux+xattrs+md5
      CONFIGS = NORMAL+sha256
      CRITICAL = CONFIGS+sha512
      READONLY = p+i+n+u+g+s+m+c+md5+sha256
    '';
  };

  # AIDE monitoring service
  systemd.services.aide-check = {
    description = "AIDE File Integrity Check";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "aide-check" ''
        # Initialize database if it doesn't exist
        if [ ! -f /var/lib/aide/aide.db ]; then
          echo "Initializing AIDE database..."
          ${pkgs.aide}/bin/aide --init
          mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
          echo "AIDE database initialized"
          exit 0
        fi

        # Run integrity check
        echo "Running AIDE integrity check..."
        ${pkgs.aide}/bin/aide --check || {
          echo "AIDE integrity check detected changes!" | \
            ${pkgs.systemd}/bin/systemd-cat -t aide-check -p warning
          
          # Send detailed report
          ${pkgs.aide}/bin/aide --check 2>&1 | \
            ${pkgs.systemd}/bin/systemd-cat -t aide-report -p info
        }

        # Update database weekly
        if [ "$(date +%u)" -eq 1 ]; then
          echo "Updating AIDE database (weekly update)..."
          ${pkgs.aide}/bin/aide --update
          mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        fi
      '';

      # Security settings
      User = "aide";
      Group = "aide";
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/aide" ];
    };
  };

  systemd.timers.aide-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # AIDE user
  users.groups.aide = { };
  users.users.aide = {
    isSystemUser = true;
    group = "aide";
    home = "/var/lib/aide";
    createHome = true;
  };

  # AIDE directory permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/aide 0750 aide aide - -"
  ];
}
