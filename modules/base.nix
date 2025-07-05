{ config, pkgs, lib, ... }:

{
  # Base system configuration that should be applied everywhere

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