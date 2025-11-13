{
  config,
  pkgs,
  ...
}: {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/homeserver
    ../../../modules/options

    # Infrastructure services
    ../../../modules/containers
    ../../../modules/database
    ../../../modules/monitoring
    ../../../modules/networking
    ../../../modules/security
    ../../../modules/services

    # User configuration
    ../../../modules/users/zeev

    # Disabled - uncomment when needed
    # ../../../modules/backup  # borgmatic config exists but not active
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. Boot Configuration
  # =================================================================
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # =================================================================
  # 4. Nixpkgs Configuration
  # =================================================================
  # Note: allowUnfree is set in flakeHelpers.nix commonModules
  nixpkgs.overlays = [
    (_final: prev: {
      python3 = prev.python3.override {
        packageOverrides = _pySelf: pySuper: {
          pyrate-limiter = pySuper.pyrate-limiter.overridePythonAttrs (_oldAttrs: {
            doCheck = false;
          });
          img2pdf = pySuper.img2pdf.overridePythonAttrs (_oldAttrs: {
            doCheck = false;
          });
        };
      };
      # Override libutp to work around CMake issues
      libutp = prev.libutp.overrideAttrs (oldAttrs: {
        meta =
          oldAttrs.meta
          // {
            broken = false;
          };
      });
    })
  ];

  # =================================================================
  # 5. Nix Configuration
  # =================================================================
  # Note: Base nix settings are in modules/base/nix-settings.nix
  # Only host-specific overrides are defined here
  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
    gcc.arch = "skylake";
    gcc.tune = "skylake";
  };

  nix.settings = {
    # Homeserver-specific: 8 cores
    cores = 8;
    max-jobs = 8;

    substituters = [
      "https://4rmcyt-homeserver.cachix.org"
    ];

    # Homeserver system features
    system-features = [
      "big-parallel"
      "gccarch-skylake"
      "kvm"
    ];

    experimental-features = [
      "flakes"
      "nix-command"
    ];

    # Homeserver trusted public keys
    # Append to base trusted public keys
    trusted-public-keys = [
      "4rmcyt-homeserver.cachix.org-1:SmDepzJsgaofX57WoXmDu+HRJl/Koh90UWsZO0k2Nkg="
    ];

    # Allow zeev to use nix commands without sudo
    trusted-users = ["zeev"];
    download-buffer-size = 1073741824;

    # Disable dirty warnings
    warn-dirty = false;
  };

  # =================================================================
  # 6. Users & Groups
  # =================================================================
  users = {
    users.git = {
      isSystemUser = true;
      description = "Git user";
      group = "git";
    };
    groups.git = {};
  };

  # =================================================================
  # 7. Networking
  # =================================================================
  networking = {
    hostName = "homeserver";
    hostId = "0b8d0f5a";
    useDHCP = true;
    enableIPv6 = false;

    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };
    tailscaleAuth = {
      enable = true;
      sopsFile = ../../../secrets/tailscale-homeserver.yaml;
      key = "tailscale_auth_key";
    };

    firewall = {
      enable = true;

      # Logging
      logReversePathDrops = true;
      logRefusedConnections = false; # Avoid log spam

      allowedTCPPorts = [
        # Base services
        22 # SSH
        80 # HTTP
        443 # HTTPS

        # 11434 # Ollama API
        # 11435 # Ollama WebUI

        # Monitoring (from monitoring.nix)
        3000 # Grafana
        9090 # Prometheus
        9100 # Node Exporter
        # 8000  # TP-Link Exporter
        # 9948  # Nextdns Exporter
        27196 # Cloudflare Exporter
        3001 # Uptime Kuma

        # Database & Infrastructure
        9091
      ];
      rejectPackets = true;
    };
  };

  # =================================================================
  # 8. Services
  # =================================================================
  services = {
    # SSH configuration
    openssh = {
      enable = true;
      extraConfig = ''
        # Global Security Settings
        KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
      '';
      hostKeys = [
        {
          type = "ed25519";
          inherit (config.sops.secrets.ssh_host_ed25519_key) path;
        }
        {
          type = "rsa";
          bits = 4096;
          inherit (config.sops.secrets.ssh_host_rsa_key) path;
        }
      ];
      knownHosts = {
        "github.com-ecdsa-sha2-nistp256".publicKey = "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
        "github.com-ed25519".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        "github.com-rsa".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
        "[u478963.your-storagebox.de]:23-ecdsa-sha2-nistp521".publicKey = "AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
        "[u478963.your-storagebox.de]:23-ssh-ed25519".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
        "[u478963.your-storagebox.de]:23-ssh-rsa".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto5melEUmWNQ+C+PwAK+MPw==";
      };
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Development services
    vscode-server.enable = true;
  };

  # =================================================================
  # 9. Programs
  # =================================================================
  programs = {
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/zeev/src/nix-config";
    };
    zsh.enable = true;
  };

  # =================================================================
  # 10. Secrets Management
  # =================================================================
  sops = {
    defaultSopsFormat = "yaml";
    secrets = {
      ssh_host_ed25519_key = {
        sopsFile = ../../../secrets/system.yaml;
        key = "ssh_host_ed25519_key";
        owner = config.users.users.root.name;
        group = config.users.groups.root.name;
        mode = "0600";
      };
      ssh_host_rsa_key = {
        sopsFile = ../../../secrets/system.yaml;
        key = "ssh_host_rsa_key";
        owner = config.users.users.root.name;
        group = config.users.groups.root.name;
        mode = "0600";
      };
    };
  };

  # =================================================================
  # 11. System Packages
  # =================================================================
  # Common packages now provided by modules/base/common-packages.nix
  # Only listing server-specific packages here
  environment.systemPackages = with pkgs; [
    # Core utilities (server-specific)
    coreutils
    lsof
    openssh

    # System monitoring & hardware
    apcupsd
    auto-cpufreq
    cpuid
    fwupd
    intel-gpu-tools
    libva-utils
    lm_sensors
    microcode-intel
    powertop
    prometheus-apcupsd-exporter
    smartmontools
    zfs

    # Network tools
    iproute2
    wireguard-tools

    # Security & secrets (server-specific)
    pinentry-tty

    # Build & deployment tools
    prometheus-cloudflare-exporter

    # Text processing
    gawk
    gnugrep
  ];
  environment.shells = with pkgs; [zsh];
  home-manager.backupFileExtension = "backup";
}
