{
  config,
  pkgs,
  lib,
  username,
  ...
}:

{

  time = {
    timeZone = "America/Edmonton"; # Change this to your timezone
  };

  services.ntp = {
    enable = false; # Use systemd-timesyncd instead
  };

  services.timesyncd = {
    enable = true;
    servers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    extraConfig = ''
      FallbackNTP=time.cloudflare.com time.google.com
      PollIntervalMinSec=32
      PollIntervalMaxSec=2048
    '';
  };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  security = {
    pam.loginLimits = [
      {
        domain = "@users";
        type = "soft";
        item = "nproc";
        value = "1024";
      }
      {
        domain = "@users";
        type = "hard";
        item = "nproc";
        value = "2048";
      }
      {
        domain = "@users";
        type = "soft";
        item = "nofile";
        value = "4096";
      }
      {
        domain = "@users";
        type = "hard";
        item = "nofile";
        value = "8192";
      }

      # Security: disable core dumps
      {
        domain = "*";
        type = "hard";
        item = "core";
        value = "0";
      }

      # Security: memory limits
      {
        domain = "@users";
        type = "soft";
        item = "memlock";
        value = "64";
      }
      {
        domain = "@users";
        type = "hard";
        item = "memlock";
        value = "64";
      }
    ];

    auditd.enable = true;
    audit = {
      enable = true;

      # Add audit rules for server security
      rules = [
        # Monitor file access
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/group -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
        "-w /etc/sudoers -p wa -k identity"

        # Monitor system calls
        "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change"
        "-a always,exit -F arch=b64 -S clock_settime -k time-change"
        "-w /etc/localtime -p wa -k time-change"

        # Monitor network configuration
        "-w /etc/hosts -p wa -k network"
        "-w /etc/sysconfig/network -p wa -k network"

        # Monitor login/logout events
        "-w /var/log/faillog -p wa -k logins"
        "-w /var/log/lastlog -p wa -k logins"
        "-w /var/log/tallylog -p wa -k logins"

        # Monitor process and session initiation
        "-w /var/run/utmp -p wa -k session"
        "-w /var/log/wtmp -p wa -k logins"
        "-w /var/log/btmp -p wa -k logins"

        # Monitor privileged commands
        "-a always,exit -F path=/usr/bin/passwd -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged-passwd"
        "-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged-sudo"

        # Monitor kernel module loading
        "-w /sbin/insmod -p x -k modules"
        "-w /sbin/rmmod -p x -k modules"
        "-w /sbin/modprobe -p x -k modules"

        # Monitor systemd
        "-w /bin/systemctl -p x -k systemd"
        "-w /etc/systemd/ -p wa -k systemd"
      ];
    };

    protectKernelImage = true;
    lockKernelModules = true; # Changed: Enable kernel module locking

    # Add additional server security
    forcePageTableIsolation = true;
    virtualisation.flushL1DataCache = "always";

    # Add AppArmor for additional security
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";

  #   # Security: disable console access for non-root
  #   useXkbConfig = false;

  #   # Disable virtual console switching for security
  #   # earlySetup = true;
  # };

  # # TTY security
  # services.getty = {
  #   greetingLine = "\\l";  # Don't show system info
  #   helpLine = "";         # Don't show help

  #   # Security: login timeout
  #   extraArgs = [ "--timeout" "60" ];
  # };

  # # Virtual console security
  # systemd.services."getty@tty1".serviceConfig = {
  #   # Restart on failure but with limits
  #   Restart = "always";
  #   RestartSec = "30s";

  #   # Security: limit login attempts
  #   StartLimitInterval = "300s";
  #   StartLimitBurst = 3;
  # };

  # # Disable unused TTYs for security
  # systemd.targets.getty.wants = [
  #   "getty@tty1.service"
  #   # Comment out unused TTYs
  #   # "getty@tty2.service"
  #   # "getty@tty3.service"
  #   # "getty@tty4.service"
  #   # "getty@tty5.service"
  #   # "getty@tty6.service"
  # ];

}
