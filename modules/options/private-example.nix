# Schema reference for the private `private` flake input (inputs.private.lib).
# NOT imported anywhere — the real values live in a separate private repo
# (git+ssh://git@github.com/4rmcyt/nix-config-private.git). This file documents
# the shape that repo's `data.nix` must provide so a reader of the public repo
# knows what is expected.
#
# Why a separate repo instead of sops: these values are consumed at Nix
# evaluation time (string interpolation, networking.hosts, option defaults),
# and sops-nix only decrypts at activation — too late for eval.
{
  identity = {
    username = "user";
    fullName = "Full Name";
    email = "user@example.com";
    gitUsername = "user";
    gitSigningKey = "0000000000000000";
    domain = "example.com";
    timezone = "Etc/UTC";
    locale = "en_US.UTF-8";
  };

  network = {
    gateway = "192.0.2.1";
    gcpRelayIp = "203.0.113.1";

    hosts = {
      homeserver_lan = "192.0.2.10";
      desktop_lan = "192.0.2.11";
      desktop_wifi = "192.0.2.12";
      matebook_wifi = "192.0.2.13";
      homeassistant-vm = "192.0.2.14";
    };

    # MACs still needed outside the reservation list (→ my.network.mac.*).
    mac = {
      desktop-wifi = "aa:bb:cc:dd:ee:ff";
    };

    # → my.network.infrastructure.*
    infrastructure = {
      isp-router = "192.0.2.254";
      switch-office = "192.0.2.2";
      switch-living-room = "192.0.2.3";
    };

    nextdns.profileId = "abcdef";

    # Full device inventory → my.network.reservations. Drives the /etc/hosts and
    # SSH aliases (modules/networking/ssh). `subnetId` is the DHCP subnet id
    # (10 trusted, 20 iot, 30 media); `aliases` is optional.
    reservations = [
      {
        hostname = "host-a";
        mac = "aa:bb:cc:00:00:01";
        ip = "192.0.2.20";
        subnetId = 10;
      }
      {
        hostname = "phone-a";
        mac = "aa:bb:cc:00:00:02";
        ip = "192.0.2.21";
        subnetId = 10;
        aliases = ["my-phone"];
      }
      {
        hostname = "plug-1";
        mac = "aa:bb:cc:00:00:03";
        ip = "198.51.100.10";
        subnetId = 20;
      }
      {
        hostname = "console-1";
        mac = "aa:bb:cc:00:00:04";
        ip = "198.51.100.20";
        subnetId = 30;
        aliases = ["game-console"];
      }
    ];
  };
}
