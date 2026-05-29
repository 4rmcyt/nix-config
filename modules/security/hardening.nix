{
  config,
  lib,
  ...
}: let
  cfg = config.my.hardening;
in {
  options.my.hardening = {
    enable = lib.mkEnableOption "System hardening (SSH, kernel, systemd defaults, auto-upgrade)";

    autoUpgrade = {
      enable = lib.mkEnableOption "Automatic NixOS upgrades from flake";
      flake = lib.mkOption {
        type = lib.types.str;
        description = "Flake URI to upgrade from.";
        example = "github:4rmcyt/nix-config#gcp-relay";
      };
      # boot instead of switch — safer on remote machines (no live service restarts)
      operation = lib.mkOption {
        type = lib.types.enum ["switch" "boot"];
        default = "boot";
        description = "nixos-rebuild operation. 'boot' is safer for remote headless servers.";
      };
      dates = lib.mkOption {
        type = lib.types.str;
        default = "04:00";
        description = "systemd.time(7) schedule for upgrades.";
      };
      randomizedDelaySec = lib.mkOption {
        type = lib.types.str;
        default = "30min";
        description = "Random delay to avoid thundering herd on flake host.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # ================================================================
    # SSH hardening
    # ================================================================
    services.openssh.settings = {
      # Modern KEX, ciphers, MACs only
      KexAlgorithms = [
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
      ];
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
      MaxAuthTries = 3;
      MaxSessions = 5;
      LoginGraceTime = 30;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      # Disable unused auth methods
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      PermitUserEnvironment = false;
      PrintLastLog = false;
    };

    # ================================================================
    # Kernel hardening (sysctl)
    # ================================================================
    boot.kernel.sysctl = {
      # Network — anti-spoofing, SYN flood protection
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_syn_retries" = 2;
      "net.ipv4.tcp_synack_retries" = 2;
      "net.ipv4.tcp_max_syn_backlog" = 4096;

      # Disable ICMP redirects (not a router)
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;

      # Ignore ICMP broadcast ping
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

      # Log martians
      "net.ipv4.conf.all.log_martians" = 1;

      # Disable source routing
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;

      # TCP performance (useful even on e2-micro)
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fastopen" = 3;

      # Memory hardening
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 1;

      # Disable magic SysRq
      "kernel.sysrq" = 0;

      # Prevent core dumps leaking
      "fs.suid_dumpable" = 0;

      # Swap minimization (e2-micro has 1GB RAM + zram)
      "vm.swappiness" = 10;
    };

    # ================================================================
    # systemd service hardening defaults
    # Applied to all services that don't override these
    # ================================================================
    systemd.services."crowdsec".serviceConfig = {
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      RestrictSUIDSGID = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      SystemCallArchitectures = "native";
    };

    systemd.services."caddy".serviceConfig = {
      NoNewPrivileges = lib.mkDefault true;
      PrivateTmp = lib.mkDefault true;
      ProtectHome = lib.mkDefault true;
      RestrictSUIDSGID = lib.mkDefault true;
      LockPersonality = lib.mkDefault true;
      RestrictRealtime = lib.mkDefault true;
      SystemCallArchitectures = lib.mkDefault "native";
    };

    systemd.services."prometheus".serviceConfig = {
      NoNewPrivileges = lib.mkDefault true;
      PrivateTmp = lib.mkDefault true;
      ProtectHome = lib.mkDefault true;
      ProtectSystem = lib.mkDefault "strict";
      RestrictSUIDSGID = lib.mkDefault true;
      LockPersonality = lib.mkDefault true;
      RestrictRealtime = lib.mkDefault true;
      SystemCallArchitectures = lib.mkDefault "native";
    };

    # ================================================================
    # Auto-upgrade
    # ================================================================
    system.autoUpgrade = lib.mkIf cfg.autoUpgrade.enable {
      enable = true;
      flake = cfg.autoUpgrade.flake;
      operation = cfg.autoUpgrade.operation;
      dates = cfg.autoUpgrade.dates;
      randomizedDelaySec = cfg.autoUpgrade.randomizedDelaySec;
      persistent = true;
      allowReboot = true;
      # GC after upgrade — 30GB disk, keep it clean
      runGarbageCollection = true;
    };
  };
}
