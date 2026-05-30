{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/options
    ../../../modules/disko/gcp
    ../../../modules/networking/caddy
    ../../../modules/security/fail2ban
    ../../../modules/security/hardening.nix
    ../../../modules/services/headscale
    (modulesPath + "/virtualisation/google-compute-image.nix")
  ];

  # =================================================================
  # System
  # =================================================================
  networking.hostName = "gcp-relay";
  time.timeZone = config.my.defaults.timezone;
  i18n.defaultLocale = config.my.defaults.locale;

  # disko (EF02 partition) sets up grub mirroredBoots automatically
  boot.loader.grub.efiSupport = false;

  zramSwap.enable = true;

  # =================================================================
  # Nix
  # =================================================================
  nix.settings = {
    cores = 2;
    max-jobs = "auto";
    trusted-users = ["root" "@wheel"];
  };

  # =================================================================
  # Sops
  # =================================================================
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "/root/.config/sops/age/keys.txt";
  };

  # =================================================================
  # Networking
  # =================================================================
  networking = {
    useNetworkd = true;
    useDHCP = lib.mkForce false;
  };

  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22 80 443];
    allowedUDPPorts = [3478];
  };

  # =================================================================
  # SSH
  # =================================================================
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
    };
  };

  # =================================================================
  # Services
  # =================================================================
  my.hardening = {
    enable = true;
    autoUpgrade = {
      enable = true;
      flake = "github:4rmcyt/nix-config#gcp-relay";
      operation = "boot";
      dates = "04:00";
      randomizedDelaySec = "30min";
    };
  };

  my.headscale = {
    enable = true;
    subdomain = "hs";
    port = 8080;
    metricsPort = 9091;
    derp = {
      regionId = 901;
      regionCode = "gcp-us-central1";
      regionName = "GCP US Central (Iowa)";
    };
  };

  my.caddy = {
    enable = true;
    headscale.enable = true;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "2 4 8 16 32 64";
      maxtime = "168h";
      overalljails = true;
    };
    ignoreIP = ["127.0.0.0/8" "100.64.0.0/10"];
    jails.sshd.settings = {
      enabled = true;
      maxretry = 3;
      bantime = "24h";
      findtime = "10m";
    };
  };

  # node-exporter — scraped by homeserver Prometheus via Tailscale after mesh is up
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9100;
    enabledCollectors = ["cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev" "stat" "time"];
  };

  # =================================================================
  # User
  # =================================================================
  users.users.${config.my.defaults.user} = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7QtXHGjNp8yxRIbMwb605n3fqFoq+PxOzbq6i2dEr6YDIKqajRNBHiEHjV3z7ABLpi2cfHPcw8Cgg/esD/98uGM9lKxdCev1VEubmsTmZAuDBz04p/S/yB7UBc5muHJLkzFNjlwMYP3x3JAr9if3nmrAZNh5qOrymZndJ7h9IT9WZNvvgFW2I+S/Ugi7eq5yRIDm5S7ADW/9wThfvG8ZqhMXDvvKXHJYx/O8D8th1ffN5l8pAJZkiV21zW0pu4od4iAaVM531H22FORAq6PbHAwr5u8a0jBlTqkwlo9x3O+hdKBVhW1XQfeRqg69lJtmUUFipl4viBj9Rpz+gtv4BjKL9ChCgqVLMLPe/bviRjqx3bvC2I78H0N51SvAh0QOj1ByAk3Xvj3R2qwk7LAmLgSlPoOsGpkbILhudF7KLJ/Uh2kpZI3NOcYdy9TYMws97zCvevgqw07HEEOydYpPB4+ml8Zzb+Tcw0U7yLRWMAB1VP1WE1vM0U6XQa7CRhcU="
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx"
  ];

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [curl htop jq tcpdump vim];

  system.stateVersion = "25.11";
}
