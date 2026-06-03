# GCP e2-micro relay: headscale control plane + DERP server + Caddy TLS termination.
# See gcp.md for deploy and first-boot instructions.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/google-compute-image.nix"
    ../../../modules/options
    ../../../modules/base/logging
    ../../../modules/monitoring/node-exporter-client.nix
    ../../../modules/networking/caddy
    ../../../modules/networking/headscale
    ../../../modules/networking/headplane
    ./crowdsec-bouncer.nix
    ../../../modules/security/fail2ban
    ../../../modules/security/hardening.nix
  ];

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

    my.crowdsecBouncer = {
      enable = true;
      lapiUrl = "http://<home-server-tailscale-ip>:<lapi-port>";
    };

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
