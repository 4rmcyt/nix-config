{
  config,
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/users/zeev.nix
    ../../modules/networking
    ../../modules/services
    ../../modules/base
    ../../modules/backup
    ../../modules/monitoring
    ../../modules/containers
    ../../modules/database
    ../../modules/security
  ];

  sops.age.keyFile = "/var/lib/sops/age.key";
  sops.defaultSopsFormat = "yaml";
  nixpkgs.config.allowUnfree = true;

  nix = {
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
      cores = 4;
      show-trace = true;
      download-buffer-size = 1073741824; # 1 GiB
      max-jobs = 4;
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  sops.secrets = {
    ssh_host_ed25519_key = {
      sopsFile = ../../secrets/system.yaml;
      key = "ssh_host_ed25519_key";
      owner = "root";
      group = "root";
      mode = "0600";
    };
    ssh_host_rsa_key = {
      sopsFile = ../../secrets/system.yaml;
      key = "ssh_host_rsa_key";
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # environment.systemPackages = with pkgs; [
  #   # Essential system tools only
  #   zsh
  #   git
  #   neovim
  #   vim
  #   wget
  #   curl
  #   jq
  #   coreutils
  #   gawk
  #   gnugrep
  #   iproute2
  #   htop
  #   btop
  #   lsof
  #   age
  #   sops
  #   ssh-to-age
  #   openssh

  #   # Development tools (consider moving to user profile)
  #   # direnv  # Move to user profile
  #   # go      # Move to user profile
  #   # python3Full  # Move to user profile

  #   # Essential admin tools
  #   mc
  #   wireguard-tools
  #   nixfmt-rfc-style
  #   nil
  #   tree
  #   smartmontools
  #   openssl
  #   fwupd
  #   nh
  #   nix-output-monitor
  #   powertop
  #   lm_sensors

  #   # Remove rarely used packages
  #   # dive
  #   # apacheHttpd
  #   # meslo-lgs-nf
  #   # yamllint
  #   # iotop
  #   # cachix
  #   # tuptime
  #   # fzf
  #   # ffmpeg
  #   # nmap
  #   # trash-cli
  #   # zip
  #   # unar
  #   # unzip
  #   # p7zip
  #   # deploy-rs
  #   # just
  #   # nixpkgs-fmt
  #   # git-crypt
  #   # pciutils
  #   # borgbackup
  #   # nix-fast-build
  #   # shfmt
  #   # zfs
  #   # nixfmt-tree
  #   # nix-inspect
  #   # nvd
  #   # nix-diff
  # ];

  environment.systemPackages = with pkgs; [
    zsh
    git
    neovim
    direnv
    pass
    vim
    wget
    curl
    jq
    coreutils
    gawk
    gnugrep
    iproute2
    mc
    htop
    btop
    lsof
    age
    sops
    ssh-to-age
    openssh
    wireguard-tools
    dive
    apacheHttpd
    meslo-lgs-nf
    yamllint
    nix-index
    iotop
    cachix
    tuptime
    fzf
    ffmpeg
    nmap
    trash-cli
    zip
    unar
    unzip
    p7zip
    go
    nextdns
    nixfmt-rfc-style
    nil
    deploy-rs
    just
    nixpkgs-fmt
    tree
    git-crypt
    python3Full
    pciutils
    borgbackup
    smartmontools
    nix-fast-build
    openssl
    fwupd
    nh
    nix-output-monitor
    shfmt
    powertop
    zfs
    lm_sensors
    nixfmt-tree
    nix-inspect
    nvd
    nix-diff
  ];

  services = {
    openssh = {
      enable = true;
      hostKeys = [
        {
          type = "ed25519";
          path = config.sops.secrets.ssh_host_ed25519_key.path;
        }
        {
          type = "rsa";
          bits = 4096;
          path = config.sops.secrets.ssh_host_rsa_key.path;
        }
      ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
      extraConfig = ''
        Match user git
          AllowTcpForwarding no
          AllowAgentForwarding no
          PasswordAuthentication no
          PermitTTY no
          X11Forwarding no
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
          " ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
        "[u478963.your-storagebox.de]:23-ecdsa-sha2-nistp521".publicKey =
          "AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
      };
    };

    ollama = {
      enable = false;
      loadModels = [ "phi3:mini" ];
    };

    vscode-server.enable = true;

    nextdns = {
      enable = true;
      arguments = [
        "-profile"
        "2bffa2"
        "-cache-size"
        "10MB"
        "--report-client-info"
      ];
    };
  };

  security.sudo.execWheelOnly = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    SystemMaxFileSize=50M
    SystemMaxFiles=10
    MaxRetentionSec=30day
    ForwardToSyslog=no
  '';

  # Add logrotate for service logs
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/nginx/*.log" = {
        frequency = "daily";
        rotate = 30;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        postrotate = "systemctl reload nginx";
      };
    };
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh.enable = true;

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/zeev/src/nixos-config";
    };
  };

  systemd.coredump.enable = false; # Disable coredumps completely

  # Disable unnecessary services for server
  services = {
    # Audio services - disable for server
    pipewire.enable = false;
    pulseaudio.enable = false;
    rtkit.enable = false;

    # Display services - disable for server
    xserver.enable = false;
    displayManager.gdm.enable = false;
    desktopManager.gnome.enable = false;

    # Bluetooth - disable for server
    blueman.enable = false;

    # Location services - disable for server
    geoclue2.enable = false;

    # Other unnecessary services
    avahi.enable = false; # mDNS discovery
    printing.enable = false; # CUPS printing

    # Keep only essential services
    haveged.enable = true; # Already enabled - good
  };

  system.stateVersion = "25.05";
}
