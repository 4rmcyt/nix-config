
{ config, pkgs, lib, ... }:

{
  
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "zeev"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      cores = 4;
      show-trace = true;
      download-buffer-size = 1073741824; # 1 GiB
      max-jobs = 4;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };

    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  time = {
    timeZone = "America/Edmonton";  # Change this to your timezone
  };

  services.timesyncd = {
    enable = true;
    servers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];
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
      { domain = "*"; type = "soft"; item = "nofile"; value = "1024"; }
      { domain = "*"; type = "hard"; item = "nofile"; value = "4096"; }
    ];

    auditd.enable = true;
    audit.enable = true;
    protectKernelImage = true;
    lockKernelModules = false; 
  };

  services.haveged.enable = true;
  services.nextdns = {
      enable = true;
      arguments = [
        "-profile"
        "nextdns0"
        "-cache-size"
        "10MB"
        "--report-client-info"
      ];
  };

  security.sudo.execWheelOnly = true;

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh.enable = true;
    nix-ld.dev.enable = false;

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}