{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/options
    ../../../modules/disko/gcp
    ../../../modules/networking/caddy
    ../../../modules/security/crowdsec
    ../../../modules/security/fail2ban
    ../../../modules/security/hardening.nix
    ../../../modules/services/headscale
  ];

  # =================================================================
  # System
  # =================================================================
  networking.hostName = "gcp-relay";
  time.timeZone = config.my.defaults.timezone;
  i18n.defaultLocale = config.my.defaults.locale;

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
  # Service toggles
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

  my.crowdsec = {
    caddy.enable = true;
    nftables = {
      enable = true;
      secretsFile = ../../../secrets/gcp.yaml;
    };
  };

  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 3000;
        base_url = "https://hs.${config.my.defaults.domain}";
        cookie_secret_path = config.sops.secrets.headplane_cookie_secret.path;
        cookie_secure = true;
        data_path = "/var/lib/headplane";
      };
      headscale = {
        url = "http://127.0.0.1:${toString config.services.headscale.port}";
        public_url = "https://hs.${config.my.defaults.domain}";
        config_path = "/etc/headscale/config.yaml";
        config_strict = false;
      };
      integration = {
        proc.enabled = true;
        agent.enabled = false;
      };
    };
  };

  sops.secrets.headplane_cookie_secret = {
    sopsFile = ../../../secrets/headplane.yaml;
    owner = config.services.headscale.user;
    group = config.services.headscale.group;
    mode = "0400";
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

  # =================================================================
  # Prometheus — homeserver Grafana scrapes via Tailscale after mesh is up
  # =================================================================
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "30d";
    globalConfig.scrape_interval = "1m";
    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
      enabledCollectors = ["cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev" "stat" "time"];
    };
    scrapeConfigs = [
      {job_name = "gcp-relay-node"; static_configs = [{targets = ["127.0.0.1:9100"];}];}
      {job_name = "headscale"; static_configs = [{targets = ["127.0.0.1:${toString config.my.headscale.metricsPort}"];}];}
      {job_name = "crowdsec"; static_configs = [{targets = ["127.0.0.1:6060"];}];}
      {job_name = "prometheus"; static_configs = [{targets = ["127.0.0.1:9090"];}];}
    ];
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

  environment.systemPackages = with pkgs; [curl htop jq nftables tcpdump vim];

  system.stateVersion = "25.11";
}
