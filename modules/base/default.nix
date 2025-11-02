{...}: {
  imports = [
    ./msmtp
    ./distributed-builds
    ./common-packages
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
}
