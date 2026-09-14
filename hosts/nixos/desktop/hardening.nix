# Desktop has no nix-mineral (unlike gcp-relay/homeserver) — these are
# plain NixOS options, not nix-mineral settings.
{
  # Max out mmap ASLR entropy (arch ceiling on x86_64 is 32/16) — pure
  # runtime sysctl, no functional dependency, flagged by
  # kernel-hardening-checker as CONFIG_ARCH_MMAP_RND_BITS FAIL (28/8 stock).
  boot.kernel.sysctl = {
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
  };

  # Generated via `shh` (Systemd Hardening Helper, strace-profiling based)
  # against sshd.service, then hand-merged from two separate profiling runs
  # (plain login, and login+scp+sftp) — kept only the directives that both
  # runs agreed were unused, dropped anything either run actually needed
  # (CAP_CHOWN/CAP_KILL/CAP_SYS_TTY_CONFIG, @chown), since profile coverage
  # is inherently incomplete and shh's SystemCallFilter failure mode is
  # EPERM (not kill), unlike a hand-written filter.
  #
  # MemoryDenyWriteExecute is the one directive here with the more dangerous
  # (kill-on-violation) failure mode — same class of directive that already
  # broke alloy.service and was deliberately left off sshd/tailscaled on
  # gcp-relay/homeserver for exactly this reason (PAM sessions are known to
  # break under it). Kept here to test since this host has no unusual PAM
  # stack (no 2FA modules), but watch `journalctl -u sshd` for SIGSYS kills
  # after real-world use (agent forwarding, port forwarding, other clients)
  # before trusting it.
  systemd.services.sshd.serviceConfig = {
    ProtectSystem = "full";
    PrivateDevices = true;
    PrivateMounts = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    LockPersonality = true;
    RestrictRealtime = true;
    ProtectClock = true;
    MemoryDenyWriteExecute = true;
    RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK" "AF_UNIX"];
    SocketBindDeny = ["ipv4:udp" "ipv6:udp"];
    CapabilityBoundingSet = ["~CAP_BLOCK_SUSPEND" "CAP_BPF" "CAP_IPC_LOCK" "CAP_MKNOD" "CAP_NET_RAW" "CAP_PERFMON" "CAP_SYS_BOOT" "CAP_SYS_MODULE" "CAP_SYS_PACCT" "CAP_SYS_PTRACE" "CAP_SYS_TIME" "CAP_SYSLOG" "CAP_WAKE_ALARM"];
    SystemCallFilter = ["~@aio:EPERM" "@clock:EPERM" "@cpu-emulation:EPERM" "@debug:EPERM" "@keyring:EPERM" "@memlock:EPERM" "@module:EPERM" "@obsolete:EPERM" "@pkey:EPERM" "@raw-io:EPERM" "@reboot:EPERM" "@sandbox:EPERM" "@swap:EPERM"];
  };
}
