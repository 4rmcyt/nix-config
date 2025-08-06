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
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "1024";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "4096";
      }
    ];

    auditd.enable = true;
    audit.enable = true;
    protectKernelImage = true;
    lockKernelModules = false;
  };

  services.haveged.enable = true;
  systemd.services.power-tune = {
    description = "Power Management tunings";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.powertop}/bin/powertop --auto-tune
    '';
    serviceConfig.Type = "oneshot";
  };
}
