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
    # ../../modules/backup
    ../../../modules/disko/homeserver
    ../../../modules/monitoring
    ../../../modules/containers
    ../../../modules/database
    ../../../modules/security
    ../../../modules/options
    ../../../modules/users/zeev
  ];
  users.users.git = {
    isSystemUser = true;
    description = "Git user";
  };
  users.groups.git = { };
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
  # 2. Nix Daemon Configuration
  # =================================================================
  nix = {
    substituters = [ "https://aseipp-nix-cache.freetls.fastly.net" ];
    package = pkgs.nixVersions.latest;
    settings = {
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
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
  # =================================================================
  # 3. Secrets Management with Sops
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
  # 4. Bootloader
  # =================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # =================================================================
  # 5. System Environment & Packages
  # =================================================================
  environment.systemPackages = with pkgs; [
    coreutils
    zfs
    openssh
    wireguard-tools
    smartmontools
    fwupd
    pciutils
    git
    statix
    cpuid
    prometheus-cloudflare-exporter
    jellyfin-ffmpeg
    libva-utils
    intel-gpu-tools
    ssh-to-age
    gnupg
    openssh
    mc
    age
    sops
    pinentry-tty
    pciutils
    wget
    curl
    gawk
    gnugrep
    iproute2
    htop
    btop
    lsof
    openssl
    powertop
    lm_sensors
    git-crypt
    prettier
    helix_git
    auto-cpufreq
    cachix

    sops
  cmake-format
  nodePackages.prettier
  rustfmt
  nixfmt-rfc-style
  deadnix
  statix
  yamlfmt
  toml-sort
  shfmt
  just
  dockfmt
  alejandra
  nix-diff
  ];
  # =================================================================
  # 6. System Services
  # =================================================================
  # This is the single, merged services block.
  services = {
    # scx.enable = true;
    # --- SSH Server ---
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
        # --- Global Security Settings ---
        # These apply to all connections and MUST be outside any Match block.
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
          " ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto5melEUmWNQ+C+PwAK+MPw==";
        "[u478963.your-storagebox.de]:23-ecdsa-sha2-nistp521".publicKey =
          "AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
      };
    };
    # --- Other Services ---
    ollama.enable = false;
    vscode-server.enable = true;
    nextdns = {
      enable = true;
      arguments = [
        "-profile"
        "nextdns0"
        "-cache-size"
        "10MB"
        "--report-client-info"
      ];
    };
  };

  # =================================================================
  # 7. System Programs & Security Settings
  # =================================================================
  programs = {
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # auto-cpufreq.enable = true;
    # auto-cpufreq.settings = {
    #   charger = {
    #     governor = "performance";
    #     turbo = "auto";
    #   };
    # };

    zsh.enable = true;

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/zeev/src/nixos-config";
    };
  };
  system.stateVersion = "25.05";
}
