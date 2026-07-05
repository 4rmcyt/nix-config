{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./firewall.nix
    ./dhcp.nix
    ../../../modules/disko/router
    ../../../modules/options
    ../../../modules/networking/tailscale
    ../../../modules/networking/unbound
    ../../../modules/monitoring/node-exporter-client.nix
    ../../../modules/monitoring/alloy-client.nix
    ../../../modules/users/zeev
  ];

  # ── Time / Locale ────────────────────────────────────────────────────────
  time.timeZone = config.my.defaults.timezone;
  i18n.defaultLocale = config.my.defaults.locale;

  # ── Secrets ─────────────────────────────────────────────────────────────
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "/root/.config/sops/age/keys.txt";
    secrets.ssh_host_ed25519_key = {
      sopsFile = ../../../secrets/system.yaml;
      key = "ssh_host_ed25519_key";
      owner = config.users.users.root.name;
      group = config.users.groups.root.name;
      mode = "0600";
    };
    # zeev_password is declared by modules/users/zeev
  };

  # ── SSH ─────────────────────────────────────────────────────────────────
  # Listen only on trusted VLAN and Tailscale — never on WAN or other VLANs.
  # nftables input chain enforces this at packet level too (defence in depth).
  services.openssh = {
    enable = true;
    ports = [22];
    # No listenAddresses — sshd listens on all interfaces.
    # Access is restricted at packet level by nftables input chain:
    # only trusted VLAN (vlan10) and tailscale0 are allowed tcp/22.
    hostKeys = [
      {
        type = "ed25519";
        inherit (config.sops.secrets.ssh_host_ed25519_key) path;
      }
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      AllowUsers = [config.my.defaults.user];
      MaxAuthTries = 3;
      LoginGraceTime = 30;
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = "no";
    };
  };

  # ── DNS (Unbound) ────────────────────────────────────────────────────────
  # Full resolver on the router: NextDNS DoT upstream + split DNS for *.example.com.
  # Listens on gateway IPs of trusted/iot/media VLANs.
  # Work VLAN clients get 1.1.1.1 directly from DHCP — no LAN DNS access.
  my.unbound = {
    enable = true;
    interfaces = [
      "127.0.0.1"
      config.my.network.vlans.trusted
      config.my.network.vlans.iot
      config.my.network.vlans.media
    ];
    tailscaleIp = "100.64.0.3";
    gcpRelayIp = "203.0.113.1";
    nextdnsProfileId = "nextdns0";
  };

  # ── Monitoring ──────────────────────────────────────────────────────────
  my.nodeExporter = {
    enable = true;
    openFirewall = false;
    extraCollectors = [
      "conntrack" # NAT table usage — critical for router health
      "ethtool" # NIC errors/drops per physical interface
      "nftables" # firewall rule counters (drops per zone)
    ];
  };

  my.alloyClient = {
    enable = true;
    lokiUrl = "http://${config.my.network.hosts.homeserver_lan}:3100/loki/api/v1/push";
  };

  # Unbound DNS exporter — cache hit rate, query latency, SERVFAIL rate
  services.prometheus.exporters.unbound = {
    enable = true;
    port = 9167;
    unbound.host = "unix:///run/unbound/unbound.ctl";
  };

  # Kea DHCP exporter — lease utilization per subnet/VLAN
  services.prometheus.exporters.kea = {
    enable = true;
    port = 9547;
    targets = ["/run/kea/kea-dhcp4.socket"];
  };

  # Kea control socket — required by kea_exporter
  services.kea.dhcp4.settings.control-socket = {
    socket-type = "unix";
    socket-name = "/run/kea/kea-dhcp4.socket";
  };

  # All exporter ports: open on tailscale only (Prometheus on homeserver scrapes via tailnet)
  # port 9100 node_exporter, 9167 unbound_exporter, 9547 kea_exporter — opened in firewall.nix

  # ── Tailscale ───────────────────────────────────────────────────────────
  # Advertises the media VLAN (192.168.30.0/24) to the Headscale tailnet.
  # ACL enforcement lives in Headscale config (out of scope here).
  # --accept-routes is off: the router doesn't need to reach other tailnet subnets.
  networking.tailscaleAuth = {
    enable = true;
    sopsFile = ../../../secrets/tailscale-router.yaml;
    loginServer = "https://hs.example.com";
    advertiseRoutes = ["192.168.30.0/24"];
    networkInterface = "enp5s0";
  };

  # ── Nix ─────────────────────────────────────────────────────────────────
  nix.settings = {
    cores = 2;
    max-jobs = 2;
    trusted-users = ["root" "@wheel"];
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
  # modules/users/zeev handles password, authorized keys, and group membership.
  # programs.zsh.enable comes from nixosBase (shared-programs.nix)
  users.users.${config.my.defaults.user}.shell = pkgs.zsh;

  # ── Journald ─────────────────────────────────────────────────────────────
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=200M
    SystemKeepFree=500M
    MaxRetentionSec=14day
  '';

  # ── NTP ─────────────────────────────────────────────────────────────────
  services.timesyncd = {
    enable = true;
    servers = ["0.pool.ntp.org" "1.pool.ntp.org" "2.pool.ntp.org"];
  };

  # ── mDNS proxy (Avahi reflector) ────────────────────────────────────────
  # Reflects mDNS between trusted/iot/media VLANs so Chromecast, AirPlay
  # and other zero-conf services are discoverable across VLANs.
  # work VLAN excluded (denied in allowInterfaces).
  services.avahi = {
    enable = true;
    reflector = true;
    allowInterfaces = ["vlan10" "enp2s0" "vlan20" "enp3s0"];
    nssmdns4 = false;
    publish.enable = false;
  };

  # ── Misc ────────────────────────────────────────────────────────────────
  zramSwap.enable = true;

  system.stateVersion = "25.11";
}
