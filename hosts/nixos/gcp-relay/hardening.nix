# nix-mineral hardening baseline (inputs.nix-mineral, tracks main in flake.nix).
#
# gcp-relay is the simplest host to harden: no podman, no ZFS/Btrfs
# subvolumes, no GUI/games/anti-cheat — just Headscale/DERP/Caddy/fail2ban on
# a single-partition GCE root disk. Starting at nix-mineral's plain defaults
# (no preset) rather than "maximum" since this is the first host running it
# and it's alpha software — layer on more (module blacklist, extras) once
# this boots clean.
{lib, ...}: {
  nix-mineral = {
    enable = true;

    # This image has no separate /boot mount. `virtualisation.googleComputeImage.efi`
    # is false here (GRUB legacy, see nixpkgs' google-compute-image.nix), so
    # nixpkgs never defines fileSystems."/boot" — nix-mineral's default /boot
    # hardening (self bind-mount with a null device) would otherwise try to
    # create that mount from nothing and fail eval.
    filesystems.normal."/boot".enable = false;

    # modules/networking/tailscale sets services.tailscale.useRoutingFeatures =
    # "both", which makes the nixpkgs tailscale module force IP forwarding on
    # via mkDefault. nix-mineral's own default (false) disables forwarding at
    # a higher override priority (900 vs mkDefault's 1000), silently winning
    # over the tailscale module's intent. Not required today (this host
    # advertises no routes/exit-node), but keep it explicit so it doesn't
    # bite if that ever changes.
    settings.network.ip-forwarding = true;

    # Default panics the kernel on any oops (boot.kernelParams "oops=panic").
    # This is a single remote instance with no physical access (GCE Serial
    # Console only) — a transient/non-malicious virtio driver oops shouldn't
    # force a reboot on top of that.
    settings.kernel.oops-panic = false;

    # Replaces the SSH cipher/auth hardening that used to come from
    # modules/security/hardening.nix (removed from this host). The
    # non-overlapping SSH settings (AllowUsers, MaxAuthTries, ...) stay
    # inline in ./default.nix.
    extras.misc.ssh-hardening = true;

    # PermitRootLogin=no already blocks SSH root login; this closes the
    # remaining path (su/console password auth as root) by making the
    # password hash unmatchable. zeev's sudo still needs its own password
    # (security.sudo.wheelNeedsPassword), unaffected.
    extras.system.lock-root = true;

    # nix-mineral's kernel-modules/combos/secureblue-disable.nix declares
    # ~20 module-blacklist combos (DVB/TV tuners, joystick, RDMA, GPIB,
    # IPSec/xfrm/esp, legacy interfaces, kernel debugging, sunrpc via
    # secureblue-additional, ...) that each default to `true` on the option
    # itself — they apply the moment nix-mineral.enable = true, regardless
    # of whether kernel-modules.disable is touched at all. Discovered this
    # by way of it breaking NFS on homeserver (secureblue-additional
    # blacklists sunrpc, which nfsd/rpc_pipefs/lockd need). Nothing on this
    # host currently depends on any of these categories, but that was true
    # on homeserver too until a reboot actually exercised it — not leaving
    # ~20 unaudited defaults active here either.
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

  # gcp-relay imports only modules/base/logging, not all of modules/base
  # (it sets its own timezone/locale inline) — so the nscd serviceConfig
  # hardening in modules/base/default.nix never reaches this host. Same
  # block, duplicated here rather than restructuring modules/base for one
  # host's import quirk.
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

  # sshd and tailscaled are structurally near-unhardenable (nixpkgs tracks
  # both as "critical to not have regressions" in
  # https://github.com/NixOS/nixpkgs/issues/377827) — sshd spawns arbitrary
  # user shells via PAM, tailscaled needs CAP_NET_ADMIN/CAP_NET_RAW and TUN
  # access. Neither will leave UNSAFE. These are additive-only directives
  # that don't touch capabilities, namespaces, or address families — same
  # subset already proven safe on headscale/nscd/couchdb in this repo.
  # Deliberately NOT set: SystemCallFilter, MemoryDenyWriteExecute,
  # PrivateUsers — same kill-on-violation directives that already crashed
  # alloy.service here (see modules/monitoring/alloy-client.nix) and were
  # skipped on headscale for the same reason; PAM sessions in particular are
  # known to break under PrivateUsers.
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

  # Not hardening, disabling: this GCE VM has no VGA console, keyboard, or
  # RF hardware at all — only the Serial Console (ttyS0, already enabled in
  # ./default.nix) is a real access path. These three units exist purely
  # because NixOS enables them by default; running-but-unused is still
  # attack surface.
  systemd.services."autovt@tty1".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."systemd-vconsole-setup".enable = false;
  systemd.services."systemd-rfkill".enable = false;

  # google-compute-config.nix (nixpkgs) writes accounts_daemon =
  # boolToString config.users.mutableUsers into instance_configs.cfg. With
  # the NixOS default (mutableUsers = true) google-guest-agent provisions
  # local accounts and SSH keys straight from GCE project/instance
  # metadata — on top of the zeev user already declared statically in
  # ./default.nix. Anyone with edit access to the project's SSH-keys
  # metadata would get a local account on this host. No config here
  # depends on mutable users, so turn the whole path off.
  users.mutableUsers = false;

  # google-guest-agent ships with zero systemd sandboxing (upstream unit is
  # just Type=notify + ExecStart + Restart=always). It's structurally like
  # sshd/tailscaled above, not like nscd: it spawns useradd/passwd for
  # account management, calls sethostname, and touches network setup — so
  # only additive-only directives that don't touch capabilities,
  # namespaces, syscalls, or address families. Deliberately NOT set:
  # ProtectClock (needs CAP_SYS_TIME for clock-skew correction),
  # ProtectHostname (agent calls sethostname; harmless here since
  # networking.hostName is mkForce'd, but would fail the syscall),
  # ProtectKernelTunables (network interface setup path), SystemCallFilter/
  # MemoryDenyWriteExecute/PrivateUsers (same directives that already
  # crashed alloy.service on this repo and are skipped on sshd/tailscaled
  # for the same reason — account management and PAM-adjacent code paths
  # don't tolerate them).
  #
  # google-guest-agent-manager.service (plugin manager, downloads and runs
  # plugins on demand from GCE metadata) is deliberately left untouched:
  # it's a code-execution channel by design, and sandboxing the loader
  # process doesn't change that — the real control is restricting who can
  # write to the project's metadata.
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
