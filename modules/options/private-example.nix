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
    mac = {
      # one "aa:bb:cc:dd:ee:ff" per key in modules/options/network.nix `mac`
    };
    infrastructure = {
      router = "192.0.2.1";
      isp-router = "192.0.2.254";
      switch-office = "192.0.2.2";
      switch-living-room = "192.0.2.3";
    };
    smart-home = {
      plugs = {
        office = "198.51.100.10";
        entrance = "198.51.100.11";
        table = "198.51.100.12";
        window = "198.51.100.13";
        salt = "198.51.100.14";
      };
      humidifier = "198.51.100.15";
      alexa-echo-show = "198.51.100.16";
    };
    entertainment = {
      roku-tv = "198.51.100.20";
      mi-box-s = "198.51.100.21";
      playstation-5 = "198.51.100.22";
      nintendo-switch = "198.51.100.23";
    };
    mobile = {
      sophia-s23-ultra = "192.0.2.20";
      volodymyr-s23 = "192.0.2.21";
    };
    nextdns.profileId = "abcdef";
  };
}
