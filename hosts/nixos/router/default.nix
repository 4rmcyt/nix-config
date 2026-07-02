{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./firewall.nix
    ./dhcp.nix
    ../../../modules/options
    ../../../modules/networking/tailscale
    ../../../modules/users/zeev
  ];

  # ── Time / Locale ────────────────────────────────────────────────────────
  time.timeZone    = config.my.defaults.timezone;
  i18n.defaultLocale = config.my.defaults.locale;

  # ── Secrets ─────────────────────────────────────────────────────────────
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "/root/.config/sops/age/keys.txt";
    secrets = {
      ssh_host_ed25519_key = {
        sopsFile = ../../../secrets/system.yaml;
        key      = "ssh_host_ed25519_key";
        owner    = config.users.users.root.name;
        group    = config.users.groups.root.name;
        mode     = "0600";
      };
      zeev_password = {
        sopsFile      = ../../../secrets/common.yaml;
        neededForUsers = true;
      };
    };
  };

  # ── SSH ─────────────────────────────────────────────────────────────────
  # Listen only on trusted VLAN and Tailscale — never on WAN or other VLANs.
  # nftables input chain enforces this at packet level too (defence in depth).
  services.openssh = {
    enable = true;
    ports  = [ 22 ];
    listenAddresses = [
      { addr = "192.168.1.1"; port = 22; }   # trusted VLAN
      # tailscale0 address is dynamic — SSH on all addresses is fine because
      # nftables already blocks WAN/iot/media/work at the input chain.
    ];
    hostKeys = [
      {
        type = "ed25519";
        inherit (config.sops.secrets.ssh_host_ed25519_key) path;
      }
    ];
    settings = {
      PasswordAuthentication      = false;
      PermitRootLogin             = "no";
      KbdInteractiveAuthentication = false;
      AllowUsers                  = [ config.my.defaults.user ];
      MaxAuthTries                = 3;
      LoginGraceTime              = 30;
      X11Forwarding               = false;
      AllowAgentForwarding        = false;
      AllowTcpForwarding          = "no";
    };
  };

  # ── Tailscale ───────────────────────────────────────────────────────────
  # Advertises the media VLAN (192.168.30.0/24) to the Headscale tailnet.
  # ACL enforcement lives in Headscale config (out of scope here).
  # --accept-routes is off: the router doesn't need to reach other tailnet subnets.
  networking.tailscaleAuth = {
    enable      = true;
    sopsFile    = ../../../secrets/tailscale-router.yaml;
    loginServer = "https://hs.example.com";
    advertiseRoutes = [ "192.168.30.0/24" ];
    networkInterface = "enp1s0";   # PLACEHOLDER — match wanInterface in networking.nix
  };

  # ── Nix ─────────────────────────────────────────────────────────────────
  nix.settings = {
    cores    = 2;
    max-jobs = 2;
    trusted-users = [ "root" "@wheel" ];
  };

  # ── Packages ─────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    curl
    htop
    iproute2
    jq
    nftables
    tcpdump
    vim
  ];

  # ── Users ────────────────────────────────────────────────────────────────
  users.users.${config.my.defaults.user} = {
    isNormalUser        = true;
    shell               = pkgs.zsh;
    extraGroups         = [ "wheel" ];
    hashedPasswordFile  = config.sops.secrets.zeev_password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks redacted@example.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+zhOyZtuInZJpTXcqN5+HBatvOn8Ud2hGRZGuFkkQc u0_a765@localhost"
    ];
  };

  # ── Journald ─────────────────────────────────────────────────────────────
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=200M
    SystemKeepFree=500M
    MaxRetentionSec=14day
  '';

  # ── Misc ────────────────────────────────────────────────────────────────
  zramSwap.enable = true;

  system.stateVersion = "25.11";
}
