# No preset applied: first host running nix-mineral (alpha software) — start at
# plain defaults, layer on more once this boots clean.
{lib, ...}: {
  nix-mineral = {
    enable = true;

    # This GCE image (GRUB legacy, no EFI) has no separate /boot mount — nix-mineral's
    # default /boot bind-mount would try to create it from nothing and fail eval.
    filesystems.normal."/boot".enable = false;

    # modules/networking/tailscale force-enables IP forwarding via mkDefault, but
    # nix-mineral's default (false) wins at a higher override priority (900 vs 1000) —
    # keep explicit even though this host advertises no routes today.
    settings.network.ip-forwarding = true;

    # Single remote GCE instance with only Serial Console access; a transient virtio
    # oops shouldn't force a reboot on top of that.
    settings.kernel.oops-panic = false;

    # Non-overlapping SSH settings (AllowUsers, MaxAuthTries, ...) stay inline in ./default.nix.
    extras.misc.ssh-hardening = true;

    # Closes the su/console root password-login path that PermitRootLogin=no doesn't
    # cover; zeev's sudo password is unaffected.
    extras.system.lock-root = true;

    # nix-mineral's secureblue-disable combos default to true regardless of whether
    # kernel-modules.disable is touched at all (broke NFS on homeserver this way —
    # secureblue-additional blacklists sunrpc) — audit explicitly rather than trust it.
    kernel-modules.disable = {
      unused-network-protocols = false;
      firewire-related = false;
      thunderbolt-related = false;
      unused-filesystems = false;
      gnss-related = false;
      cdrom-related = false;
      esp4-and-esp6 = false;
      xfrm-related = false;
      ipsec-related = false;
      l2tp-related = false;
      legacy-interfaces = false;
      kernel-debugging-related = false;
      automotive-related = false;
      rdma-related = false;
      gpib-related = false;
      dvb-and-tv-receivers = false;
      joystick-drivers = false;
      remote-controls = false;
      legacy-digital-cameras = false;
      radio-tuners = false;
      secureblue-additional = false;
    };
  };

  # gcp-relay only imports modules/base/logging, not all of modules/base, so the
  # nscd hardening block there never reaches this host — duplicated here.
  systemd.services.nscd.serviceConfig = {
    CapabilityBoundingSet = lib.mkForce "";
    RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
    SystemCallFilter = lib.mkDefault ["@system-service"];
    SystemCallArchitectures = lib.mkDefault "native";
    ProtectClock = lib.mkDefault true;
    ProtectKernelLogs = lib.mkDefault true;
    ProtectKernelModules = lib.mkDefault true;
    ProtectKernelTunables = lib.mkDefault true;
    ProtectControlGroups = lib.mkDefault true;
    ProtectHostname = lib.mkDefault true;
    RestrictNamespaces = lib.mkDefault true;
    RestrictSUIDSGID = lib.mkDefault true;
    LockPersonality = lib.mkDefault true;
    RestrictRealtime = lib.mkDefault true;
    MemoryDenyWriteExecute = lib.mkDefault true;
    ProtectProc = lib.mkDefault "invisible";
    ProcSubset = lib.mkDefault "pid";
    UMask = lib.mkDefault "0077";
    RemoveIPC = lib.mkDefault true;
    PrivateUsers = lib.mkDefault true;
  };

  # sshd (PAM shells) and tailscaled (needs CAP_NET_ADMIN/RAW + TUN) can't go past
  # UNSAFE. Deliberately NOT set: SystemCallFilter/MemoryDenyWriteExecute/PrivateUsers —
  # same directives that crashed alloy.service (modules/monitoring/alloy-client.nix);
  # PAM sessions are known to break under PrivateUsers.
  systemd.services.sshd.serviceConfig = {
    ProtectClock = lib.mkDefault true;
    ProtectKernelLogs = lib.mkDefault true;
    ProtectKernelModules = lib.mkDefault true;
    ProtectKernelTunables = lib.mkDefault true;
    ProtectHostname = lib.mkDefault true;
    LockPersonality = lib.mkDefault true;
    RestrictRealtime = lib.mkDefault true;
    RemoveIPC = lib.mkDefault true;
    UMask = lib.mkDefault "0077";
  };

  systemd.services.tailscaled.serviceConfig = {
    ProtectClock = lib.mkDefault true;
    ProtectKernelLogs = lib.mkDefault true;
    ProtectHostname = lib.mkDefault true;
    LockPersonality = lib.mkDefault true;
    RestrictRealtime = lib.mkDefault true;
    RemoveIPC = lib.mkDefault true;
    UMask = lib.mkDefault "0077";
  };

  # This GCE VM has no VGA console/keyboard/RF hardware — only Serial Console (ttyS0)
  # is a real access path; these units exist only because NixOS enables them by default.
  systemd.services."autovt@tty1".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."systemd-vconsole-setup".enable = false;
  systemd.services."systemd-rfkill".enable = false;

  # With mutableUsers=true, google-guest-agent provisions local accounts/SSH keys from
  # GCE project metadata — anyone with metadata edit access would get a local account.
  users.mutableUsers = false;

  # google-guest-agent has zero systemd sandboxing upstream and spawns useradd/passwd,
  # calls sethostname, and touches network setup — only additive directives that don't
  # touch capabilities/namespaces/syscalls/address families are safe here.
  # google-guest-agent-manager.service (downloads/runs plugins from GCE metadata) is left
  # untouched — it's a code-execution channel by design; the real control is metadata ACLs.
  systemd.services.google-guest-agent.serviceConfig = {
    ProtectKernelLogs = lib.mkDefault true;
    ProtectKernelModules = lib.mkDefault true;
    ProtectControlGroups = lib.mkDefault true;
    LockPersonality = lib.mkDefault true;
    RestrictRealtime = lib.mkDefault true;
    RemoveIPC = lib.mkDefault true;
    UMask = lib.mkDefault "0077";
  };
}
