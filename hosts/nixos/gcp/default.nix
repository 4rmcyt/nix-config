# GCP e2-micro relay: headscale control plane + DERP server + Caddy TLS termination.
# See gcp.md for deploy and first-boot instructions.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  cfg = config.my.crowdsec;
  isRemoteLapi = cfg.nftables.lapiUrl != "http://127.0.0.1:8088";

  crowdsecPlugin = pkgs.fetchFromGitHub {
    owner = "maxlerebourg";
    repo = "crowdsec-bouncer-traefik-plugin";
    rev = "v1.5.1";
    hash = "sha256-w4tQjJjcHg6P5ew7kkj4j5cduLIrs5BiQlvxkJFi6So=";
  };

  geoblockPlugin = pkgs.fetchFromGitHub {
    owner = "david-garcia-garcia";
    repo = "traefik-geoblock";
    rev = "v1.1.4";
    hash = "sha256-qgLM6nrlDXLS7OsLw6cDKjhx9B+CnJR4TB32pg/MvEo=";
  };
in
{
  imports = [
    "${modulesPath}/virtualisation/google-compute-image.nix"
    ../../../modules/options
    ../../../modules/base/logging
    ../../../modules/monitoring/node-exporter-client.nix
    ../../../modules/networking/caddy
    ../../../modules/networking/headscale
    ../../../modules/networking/headplane
    ../../../modules/security/fail2ban
    ../../../modules/security/hardening.nix
  ];

  options.my.crowdsec = {
    traefik.enable = lib.mkEnableOption "CrowdSec Traefik bouncer plugin wiring";
    caddy.enable = lib.mkEnableOption "CrowdSec Caddy log acquisition";
    nftables = {
      enable = lib.mkEnableOption "CrowdSec nftables firewall bouncer";
      lapiUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8088";
        description = "CrowdSec LAPI URL (local or remote via Tailscale).";
      };
      secretsFile = lib.mkOption {
        type = lib.types.path;
        default = ../../../secrets/crowdsec.yaml;
        description = "Sops file containing crowdsec_bouncer_key_nftables.";
      };
    };
  };

  config = {
    # =================================================================
    # System
    # =================================================================
    time.timeZone = config.my.defaults.timezone;
    i18n.defaultLocale = config.my.defaults.locale;

    # google-compute-image.nix overrides
    security.googleOsLogin.enable = lib.mkForce false;

    # Serial console access (GCP serial port)
    boot.kernelParams = [ "console=ttyS0,38400n8d" ];
    systemd.services."serial-getty@ttyS0".enable = true;
    networking.hostName = lib.mkForce "gcp-relay";
    boot.loader.grub.configurationLimit = lib.mkForce 2;
    security.sudo.wheelNeedsPassword = lib.mkForce false;

    virtualisation.diskSize = 10 * 1024;

    zramSwap.enable = true;

    # =================================================================
    # Nix
    # =================================================================
    nix.settings = {
      cores = 2;
      max-jobs = "auto";
      trusted-users = [
        "root"
        "@wheel"
      ];
      require-sigs = false;
    };

    # =================================================================
    # Sops
    # =================================================================
    sops.age.keyFile = "/root/.config/sops/age/keys.txt";

    sops.secrets.gcp_relay_host_ed25519 = {
      sopsFile = ../../../secrets/gcp-relay-host-ed25519;
      format = "binary";
      path = "/etc/ssh/ssh_host_ed25519_key";
      owner = "root";
      group = "root";
      mode = "0600";
    };

    services.openssh.hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    # =================================================================
    # Networking
    # =================================================================
    networking = {
      useNetworkd = true;
      useDHCP = lib.mkForce false;
      firewall = {
        enable = lib.mkForce true;
        allowedTCPPorts = [
          22
          80
          443
          9100
        ];
        allowedUDPPorts = [ 3478 ];
      };
    };

    systemd.network = {
      enable = true;
      networks."10-eth" = {
        matchConfig.Name = "en*";
        networkConfig.DHCP = "yes";
      };
    };

    # =================================================================
    # SSH
    # =================================================================
    services.openssh = {
      enable = true;
      ports = [ 22 ];
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

    my.crowdsec.nftables = {
      enable = true;
      secretsFile = ../../../secrets/crowdsec-gcp.yaml;
    };

    my.crowdsec.caddy.enable = true;

    my.nodeExporter.enable = true;

    my.headscale = {
      enable = true;
      subdomain = "hs";
      port = 8080;
      metricsPort = 9091;
      dns = {
        splitNameservers = [ "100.64.0.3" ];
        splitDomains = [ "example.com" ];
      };
      derp = {
        regionId = 901;
        regionCode = "gcp-us-central1";
        regionName = "GCP US Central (Iowa)";
        latitude = 41.878;
        longitude = -93.097;
      };
    };

    my.caddy = {
      enable = true;
      headscale.enable = true;
      headplane.enable = true;
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
      ignoreIP = [
        "127.0.0.0/8"
        "100.64.0.0/10"
      ];
      jails.sshd.settings = {
        enabled = true;
        maxretry = 3;
        bantime = "24h";
        findtime = "10m";
      };
    };

    # Limit journal size — 30GB root disk
    services.journald.extraConfig = ''
      SystemMaxUse=500M
      SystemKeepFree=2G
      MaxRetentionSec=14day
    '';

    # =================================================================
    # CrowdSec
    # =================================================================
    sops.secrets.crowdsec_bouncer_key = lib.mkIf cfg.traefik.enable {
      sopsFile = ../../../secrets/crowdsec.yaml;
      owner = "traefik";
      group = "traefik";
      mode = "0400";
    };

    sops.secrets.crowdsec_bouncer_key_nftables = lib.mkIf cfg.nftables.enable {
      sopsFile = cfg.nftables.secretsFile;
      owner = "root";
      mode = "0400";
    };

    services.crowdsec = lib.mkIf (!isRemoteLapi) {
      enable = true;

      hub.collections = [
        "crowdsecurity/linux"
        "crowdsecurity/sshd"
      ]
      ++ lib.optionals cfg.traefik.enable [ "crowdsecurity/traefik" ]
      ++ lib.optionals cfg.caddy.enable [ "crowdsecurity/caddy" ];

      settings.general.api.server = {
        enable = true;
        listen_uri = "127.0.0.1:8088";
      };

      settings.lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-credentials.yaml";

      localConfig.acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
      ]
      ++ lib.optionals cfg.traefik.enable [
        {
          filenames = [ "/var/log/traefik/access.log" ];
          labels.type = "traefik";
        }
      ]
      ++ lib.optionals cfg.caddy.enable [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=caddy.service" ];
          labels.type = "caddy";
        }
      ];
    };

    environment.etc."crowdsec/parsers/s02-enrich/tailscale-whitelist.yaml" = lib.mkIf (!isRemoteLapi) {
      user = "crowdsec";
      group = "crowdsec";
      mode = "0640";
      text = ''
        name: tailscale-whitelist
        description: "Whitelist Tailscale CGNAT range"
        filter: "evt.Meta.source_ip startsWith '100.'"
        whitelist:
          reason: "Tailscale CGNAT"
          cidr:
            - "100.64.0.0/10"
      '';
    };

    environment.etc."crowdsec/postoverflows/s01-whitelist/local-trusted-networks.yaml" =
      lib.mkIf (!isRemoteLapi)
        {
          user = "crowdsec";
          group = "crowdsec";
          mode = "0640";
          text = ''
            name: local-trusted-networks
            description: "Whitelist LAN, Tailscale and Cloudflare IPs"
            whitelist:
              reason: "trusted network"
              ip:
                - "127.0.0.1"
                - "192.168.1.1"
              cidr:
                - "192.168.1.0/24"
                - "10.0.0.0/8"
                - "100.64.0.0/10"
                - "173.245.48.0/20"
                - "103.21.244.0/22"
                - "103.22.200.0/22"
                - "103.31.4.0/22"
                - "141.101.64.0/18"
                - "108.162.192.0/18"
                - "190.93.240.0/20"
                - "188.114.96.0/20"
                - "197.234.240.0/22"
                - "198.41.128.0/17"
                - "162.158.0.0/15"
                - "104.16.0.0/13"
                - "104.24.0.0/14"
                - "172.64.0.0/13"
                - "131.0.72.0/22"
          '';
        };

    services.crowdsec-firewall-bouncer = lib.mkIf cfg.nftables.enable {
      enable = true;
      registerBouncer.enable = false;
      settings = {
        mode = "nftables";
        api_url = cfg.nftables.lapiUrl;
      };
      secrets.apiKeyPath = config.sops.secrets.crowdsec_bouncer_key_nftables.path;
    };

    systemd.services.crowdsec-firewall-bouncer = lib.mkIf cfg.nftables.enable {
      after = [ "nftables.service" ] ++ lib.optionals (!isRemoteLapi) [ "crowdsec.service" ];
      requires = lib.optionals (!isRemoteLapi) [ "crowdsec.service" ];
    };

    systemd.services.crowdsec = {
      serviceConfig.ExecStartPre = lib.mkForce [ "" ];
      serviceConfig.ReadWritePaths = [ "/var/lib/crowdsec" ];
    };

    networking.nftables.enable = lib.mkIf cfg.nftables.enable true;

    systemd.tmpfiles.rules = lib.mkIf cfg.traefik.enable [
      "d /var/lib/traefik/plugins-local 0750 traefik traefik -"
      "d /var/lib/traefik/plugins-local/src 0750 traefik traefik -"
      "d /var/lib/traefik/plugins-local/src/github.com 0750 traefik traefik -"
      "d /var/lib/traefik/plugins-local/src/github.com/maxlerebourg 0750 traefik traefik -"
      "d /var/lib/traefik/plugins-local/src/github.com/david-garcia-garcia 0750 traefik traefik -"
      "L+ /var/lib/traefik/plugins-local/src/github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin - - - - ${crowdsecPlugin}"
      "L+ /var/lib/traefik/plugins-local/src/github.com/david-garcia-garcia/traefik-geoblock - - - - ${geoblockPlugin}"
    ];

    # =================================================================
    # User
    # =================================================================
    users.users.${config.my.defaults.user} = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7QtXHGjNp8yxRIbMwb605n3fqFoq+PxOzbq6i2dEr6YDIKqajRNBHiEHjV3z7ABLpi2cfHPcw8Cgg/esD/98uGM9lKxdCev1VEubmsTmZAuDBz04p/S/yB7UBc5muHJLkzFNjlwMYP3x3JAr9if3nmrAZNh5qOrymZndJ7h9IT9WZNvvgFW2I+S/Ugi7eq5yRIDm5S7ADW/9wThfvG8ZqhMXDvvKXHJYx/O8D8th1ffN5l8pAJZkiV21zW0pu4od4iAaVM531H22FORAq6PbHAwr5u8a0jBlTqkwlo9x3O+hdKBVhW1XQfeRqg69lJtmUUFipl4viBj9Rpz+gtv4BjKL9ChCgqVLMLPe/bviRjqx3bvC2I78H0N51SvAh0QOj1ByAk3Xvj3R2qwk7LAmLgSlPoOsGpkbILhudF7KLJ/Uh2kpZI3NOcYdy9TYMws97zCvevgqw07HEEOydYpPB4+ml8Zzb+Tcw0U7yLRWMAB1VP1WE1vM0U6XQa7CRhcU="
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks redacted@example.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+zhOyZtuInZJpTXcqN5+HBatvOn8Ud2hGRZGuFkkQc u0_a765@localhost"
      ];
    };

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks redacted@example.com"
    ];

    programs.zsh.enable = true;

    environment.systemPackages = with pkgs; [
      curl
      htop
      jq
      tcpdump
      vim
      kitty.terminfo
      wezterm.terminfo
    ];

    system.stateVersion = "25.11";
  };
}
