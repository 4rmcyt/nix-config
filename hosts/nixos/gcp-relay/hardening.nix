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
  };

  # gcp-relay imports only modules/base/logging, not all of modules/base
  # (it sets its own timezone/locale inline) — so the nscd serviceConfig
  # hardening in modules/base/default.nix never reaches this host. Same
  # block, duplicated here rather than restructuring modules/base for one
  # host's import quirk.
  systemd.services.nscd.serviceConfig = {
    CapabilityBoundingSet = lib.mkDefault [];
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
}
