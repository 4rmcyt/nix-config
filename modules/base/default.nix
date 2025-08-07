{ lib, config, ... }:
{
  imports = [
    ./auto_upgrade
    ./msmtp
    ./logging
  ];

  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_US.UTF-8";

  services.timesyncd = {
    enable = true;
    servers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];
  };

  environment.shellInit = ''
    umask 027
    # WARNING: The 'export PATH' line from your original file was removed.
    # It was too restrictive and would break user-installed packages.
    # The default NixOS PATH is already secure.
    unset LD_PRELOAD LD_LIBRARY_PATH
  '';

  environment.interactiveShellInit = ''
    export TMOUT=1800 # Auto-logout after 30 minutes
    export HISTCONTROL="ignoreboth:erasedups"
    export HISTSIZE=1000
  '';

  security = {
    sudo.execWheelOnly = true;
    protectKernelImage = true;
    lockKernelModules = true;
    forcePageTableIsolation = true;
    virtualisation.flushL1DataCache = "always";
    apparmor.enable = true;
    auditd.enable = true;
    security.audit.rules = [
      # Base rules (from your config)
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/group -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      "-w /etc/sudoers -p wa -k identity"

      # Monitor time changes
      "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change"
      "-a always,exit -F arch=b64 -S clock_settime -k time-change"

      # Monitor privileged command execution
      "-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=-1 -k privileged-sudo"
      "-a always,exit -F path=/usr/bin/passwd -F perm=x -F auid>=1000 -F auid!=-1 -k privileged-passwd"

      # Monitor kernel module loading
      "-w /sbin/insmod -p x -k modules"
      "-w /sbin/rmmod -p x -k modules"
      "-w /sbin/modprobe -p x -k modules"
      "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules"
    ];

    pam.loginLimits = [
      {
        domain = "*";
        type = "hard";
        item = "core";
        value = "0";
      }
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
    ];
  };

  boot.tmp.useTmpfs = true;

  system.stateVersion = "25.05";
}
