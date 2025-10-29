{...}: {
  imports = [
    ./auto_upgrade
    ./msmtp
    ./logging
    ./nix-settings.nix
    ./distributed-builds.nix
    ../roles
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

  system.stateVersion = "25.05";
}
