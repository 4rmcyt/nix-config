
{ config, pkgs, lib, ... }:

{
  # Base system configuration that should be applied everywhere

  # Time and locale configuration
  time = {
    timeZone = "America/Edmonton";  # Change this to your timezone
    hardwareClockInUTC = true;
  };

  # Enable automatic time synchronization
  services.timesyncd = {
    enable = true;
    servers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];
  };

  # Locale settings (moved to top level, NOT under security)
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

  # System hardening
  security = {
    # Protect against fork bombs and other resource exhaustion
    pam.loginLimits = [
      { domain = "*"; type = "soft"; item = "nofile"; value = "1024"; }
      { domain = "*"; type = "hard"; item = "nofile"; value = "4096"; }
    ];

    # Audit system events
    auditd.enable = true;
    audit.enable = true;

    # Enable security protections
    protectKernelImage = true;
    lockKernelModules = false; # Be careful with this, may break some hardware
  };

  # Better entropy gathering for improved cryptographic operations
  services.haveged.enable = true;

  # Automatic system maintenance
  nix = {
    # Auto garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Auto optimize nix store
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  # System backup recommendations (commented for reference)
  # services.borgbackup.jobs.homeserver = {
  #   paths = [
  #     "/home"
  #     "/var/lib"
  #     "/etc"
  #   ];
  #   exclude = [
  #     "**/node_modules"
  #     "**/.cache"
  #     "/var/lib/docker"
  #   ];
  #   repo = "/mnt/backup/homeserver";
  #   encryption.mode = "repokey";
  #   encryption.passphrase = "sops-file-reference";
  #   compression = "auto,lzma";
  #   startAt = "daily";
  # };
}