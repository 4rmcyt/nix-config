{
  config,
  pkgs,
  ...
}:
{
  # =================================================================
  # 1. Imports & Global Settings
  # =================================================================
  imports = [
    ./hardware-configuration.nix
    ../../../modules/networking
    ../../../modules/services
    ../../../modules/base
    # ../../../modules/backup
    ../../../modules/disko/homeserver
    ../../../modules/monitoring
    ../../../modules/containers
    ../../../modules/database
    ../../../modules/security
    ../../../modules/options
    ../../../modules/users/zeev
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    python3 = pkgs.python3.override {
      packageOverrides = _pySelf: pySuper: {
        pyrate-limiter = pySuper.pyrate-limiter.overridePythonAttrs (_oldAttrs: {
          doCheck = false; # Skip tests
        });
      };
    };
  };

  # =================================================================
  # 3. Bootloader
  # =================================================================
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # =================================================================
  # 4. User & Group Management
  # =================================================================
  users = {
    users.git = {
      isSystemUser = true;
      description = "Git user";
      group = "git";
    };
    groups.git = { };
  };

  # =================================================================
  # 5. Nix Configuration
  # =================================================================
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      substituters = [
        "https://nix-community.cachix.org"
        "https://homeserver.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "homeserver.cachix.org-1:0vStm6koDUwET/iWYhbKpsuVO4v3UgN3510zYH9YpZU="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      fallback = true;
      system-features = [
        "big-parallel"
        "kvm"
      ];
      trusted-users = [ "zeev" ];
      warn-dirty = false;
      cores = 8;
      max-jobs = 8;
      show-trace = true;
      download-buffer-size = 1073741824;
    };
  };

  # =================================================================
  # 6. Secrets Management with SOPS
  # =================================================================
  sops = {
    age.keyFile = "/var/lib/sops/age.key";
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
  # 7. System Packages
  # =================================================================
  environment.systemPackages = with pkgs; [
    # Core utilities
    coreutils
    openssh
    git
    mc
    wget
    curl
    htop
    btop
    lsof

    # System monitoring & hardware
    zfs
    smartmontools
    fwupd
    pciutils
    cpuid
    libva-utils
    intel-gpu-tools
    powertop
    lm_sensors
    auto-cpufreq

    # Network tools
    wireguard-tools
    iproute2

    # Security & secrets
    age
    sops
    ssh-to-age
    gnupg
    pinentry-tty
    git-crypt

    # Development & formatting tools
    statix
    helix
    prettier
    cmake-format
    nodePackages.prettier
    rustfmt
    nixfmt-rfc-style
    deadnix
    yamlfmt
    toml-sort
    shfmt
    just
    dockfmt
    alejandra
    nix-diff

    # Build tools
    cachix
    prometheus-cloudflare-exporter

    # Text processing
    gawk
    gnugrep
    openssl
  ];

  # =================================================================
  # 8. System Services
  # =================================================================

  networking = {
    dnssec = {
      enable = true;
      profileId = "2bffa2";
    };
    tailscaleAuth = {
      enable = true;
      sopsFile = ../../../secrets/tailscale-desktop.yaml;
      key = "tailscale_auth_key";
    };
  };

  services = {
    # SSH configuration
    openssh = {
      enable = true;
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
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
      extraConfig = ''
        # Global Security Settings
        KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
      '';
      knownHosts = {
        "github.com-ed25519".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        "github.com-rsa".publicKey =
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
        "github.com-ecdsa-sha2-nistp256".publicKey =
          "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
        "[u478963.your-storagebox.de]:23-ssh-ed25519".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
        "[u478963.your-storagebox.de]:23-ssh-rsa".publicKey =
          "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto5melEUmWNQ+C+PwAK+MPw==";
        "[u478963.your-storagebox.de]:23-ecdsa-sha2-nistp521".publicKey =
          "AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
      };
    };

    # Other services
    vscode-server.enable = true;
  };

  # =================================================================
  # 9. Programs Configuration
  # =================================================================
  programs = {
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh.enable = true;

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/zeev/src/nixos-config";
    };

    # Uncomment when needed
    # auto-cpufreq = {
    #   enable = true;
    #   settings = {
    #     charger = {
    #       governor = "performance";
    #       turbo = "auto";
    #     };
    #   };
    # };
  };
}
