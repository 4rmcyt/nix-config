# nix-mineral hardening baseline (inputs.nix-mineral, tracks main in flake.nix).
#
# Desktop is the highest-risk host to harden: unlike homeserver/gcp-relay
# (headless services only), this box runs Steam/Proton (bubblewrap
# sandboxing), GameConqueror/scanmem (ptrace), waydroid, virt-manager/libvirt
# (KVM + nested), and podman containers — all lean on kernel surfaces
# nix-mineral restricts by default. No preset applied (same reasoning as
# gcp-relay: start at plain defaults, layer on deliberately). libvirt/
# waydroid/podman compat is untested territory for nix-mineral itself (no
# upstream issues or docs found for any of the three) — rebuild and verify
# each subsystem individually rather than trusting this file blind.
{
  nix-mineral = {
    enable = true;

    # Root fs is Btrfs with real subvolumes (modules/disko/desktop), not a
    # single partition — same class of issue as homeserver's separate ZFS
    # datasets (nix-mineral's own FAQ / issue #11: default self bind-mount
    # assumes the hardened path is a subdirectory of the fs it's already on,
    # and breaks stage-2 activation when it's actually a distinct mount).
    # /var/log and /home are separate subvolumes → need bind=false. /nix,
    # /home/games, and /var/lib/libvirt are also separate subvolumes but
    # aren't in nix-mineral's default filesystems.normal set at all (only
    # /home, /root, /tmp, /var, /var/tmp, /var/log, /boot, /srv, /etc are),
    # so they're simply never touched — no override needed there.
    filesystems.normal."/var/log".options."bind" = false;

    # Same gitstatusd-under-noexec issue as homeserver's /home (see that
    # host's hardening.nix for the full story): zeev's zsh/p10k lives here
    # too (desktop/default.nix: zeev.shell = lib.mkForce pkgs.zsh).
    filesystems.normal."/home" = {
      options."bind" = false;
      options."noexec" = false;
    };

    # /var itself is NOT a separate subvolume here (only /var/log and
    # /var/lib/libvirt are carved out) — it's a plain subdirectory of the
    # root subvolume, so nix-mineral's default self bind-mount is correct
    # and applies its default noexec=true. That noexec would land on
    # /var/lib/containers (podman's storage graphroot, modules/containers)
    # since podman has no separate subvolume either — breaks every
    # container that execs a binary from its image layers. Same fix
    # homeserver uses for *arr binaries under /var/lib.
    filesystems.normal."/var/lib" = {
      enable = true;
      options."noexec" = false;
      options."exec" = true;
    };

    # modules/containers (podman bridge networking) and virt-manager's
    # default libvirt NAT network (virbr0) both need forwarding for
    # container/VM outbound traffic — same requirement homeserver has for
    # podman, plus libvirt NAT on top. nix-mineral's own default (false)
    # force-disables it at mkOverride 900, above the modules that'd
    # otherwise enable it via mkDefault.
    settings.network.ip-forwarding = true;

    # Desktop runs wired (enp12s0) and wifi (wlp13s0) simultaneously, both
    # with active default routes at different metrics (see `ip route`).
    # nix-mineral's default rp_filter=strict (mkOverride 900) drops packets
    # whose reverse path (per the routing table) doesn't match the
    # interface they arrived on — exactly what happens here for wifi
    # traffic when the wired route is preferred. Disabling it is the
    # documented trade-off for multi-homed hosts.
    settings.network.rp-filter = false;

    # nix-mineral's default "restrict" disables accept_ra_pinfo, which
    # breaks IPv6 SLAAC prefix autoconfiguration — desktop's IPv6 addresses
    # are SLAAC-assigned. "on" keeps normal RA handling.
    settings.network.router-advertisements = "on";

    # nix-mineral defaults binfmt-misc to false (disabled) — breaks Wine/
    # Proton (Steam), Java, and AppImages, which this host runs.
    settings.kernel.binfmt-misc = true;

    # Default auto-true on kernel >=6.17 (xanmod 7.2.4 qualifies) — adds
    # significant memory-allocation overhead for red-zoning/sanity checks.
    # No active memory-corruption debugging need here; pure perf cost on a
    # gaming box.
    settings.kernel.slab-debug = false;

    # Default false disables 32-bit vDSO — breaks native (non-Proton) 32-bit
    # Linux games in the Steam library.
    settings.kernel.vdso32 = true;

    # Perf over the SMT-disabling default — gaming box, not a multi-tenant
    # server. Still applies standard CPU mitigations, just keeps SMT on.
    settings.kernel.cpu-mitigations = "smt-on";

    # Default true randomizes MAC via NetworkManager (active on this host).
    # my.network.hosts.desktop_lan/desktop_wifi imply DHCP reservations keyed
    # to the real hardware MAC — randomizing would break those reservations.
    settings.network.random-mac = false;

    # Default (1) conflicts with ipv6-tempaddr (also default true, needs
    # room for permanent + temporary address) — this host runs both SLAAC
    # and privacy-extension temp addresses simultaneously.
    settings.network.max-addresses = 8;

    # Both default true, both explicitly documented as targeting "multiple
    # interfaces on the same subnet" — exactly this host's enp12s0+wlp13s0
    # dual-homed setup. arp_ignore=2 (ignore, default "link") only answers
    # ARP if the target matches the SPECIFIC incoming interface; arp_filter=1
    # restricts replies to one interface based on routing table state. With
    # two interfaces racing on the same L2 segment this desyncs which
    # interface the router thinks owns which IP, black-holing return WAN
    # traffic for whichever interface loses the race — reproduced live:
    # enp12s0 got 100% packet loss to any WAN address while wlp13s0 worked
    # fine on the same gateway, independent of MAC/IP renewal.
    settings.network.arp = {
      ignore = "none";
      filter = false;
    };

    # Default false disables ia32_emulation entirely — breaks 32-bit Steam
    # games/libraries outright.
    settings.system.multilib = true;

    # Default "ptrace" restricts mmap/mprotect remapping to ptrace-based
    # access for every process on the system, not just debugging tools —
    # likely to break JIT compilers, Wine, and dynamic linkers broadly.
    settings.system.proc-mem-force = "none";

    # Default false disables core dumps — want them for debugging game/
    # Proton crashes.
    settings.debug.coredump = true;

    # Default true pulls Kicksecure's bluetooth/main.conf, which sets
    # AutoEnable=false — the adapter would stay off after every boot until
    # manually enabled. Breaks the always-used BT headset.
    settings.etc.kicksecure-bluetooth = false;

    # Default panics the kernel on any oops (boot.kernelParams "oops=panic").
    # A flaky GPU/wine driver oops mid-game or mid-VM shouldn't force an
    # unclean reboot — same reasoning as homeserver/gcp-relay.
    settings.kernel.oops-panic = false;

    # CRITICAL: default "restricted" (ptrace_scope=3) is applied via
    # mkForce (priority 50) — that silently wins over the plain-priority
    # `boot.kernel.sysctl."kernel.yama.ptrace_scope" = 0` already set in
    # modules/gaming/default.nix for GameConqueror/scanmem (which need to
    # attach to non-descendant processes, so even "relaxed"=1 isn't
    # permissive enough). "none" is documented as leaving the sysctl at
    # kernel default rather than forcing anything — verify after rebuild
    # with `sysctl kernel.yama.ptrace_scope` that it reads 0, not 1; if
    # nix-mineral's "none" turns out to itself force the kernel's own
    # default (1) rather than skipping the setting entirely, this needs
    # revisiting (likely moving the override into this file with
    # lib.mkForce instead of relying on modules/gaming).
    settings.system.yama = "none";

    # Same non-negotiable SSH cipher/auth hardening as homeserver/gcp-relay.
    # Disables X11/TCP/agent forwarding — confirmed acceptable, desktop
    # doesn't tunnel through its own sshd. Non-overlapping settings
    # (PasswordAuthentication, PermitRootLogin) stay inline in ./default.nix.
    extras.misc.ssh-hardening = true;

    # PermitRootLogin=no already blocks SSH root login; this closes the
    # remaining path (su/console password auth as root) by making the
    # password hash unmatchable. zeev's sudo still needs its own password
    # (security.sudo.wheelNeedsPassword), unaffected.
    extras.system.lock-root = true;

    # Every category audited against actual hardware/config on this host
    # (lspci/lsusb/lsblk/ip link, repo grep for VPN/NFS usage) rather than
    # left at nix-mineral's own default (touching kernel-modules.disable at
    # all pulls in the full secureblue combo set, defaulting every category
    # to true). false = hardware/usage present; true = confirmed absent.
    kernel-modules.disable = {
      bluetooth-related = false;
      intelme-related = false;
      unused-filesystems = false;
      secureblue-additional = false;
      joystick-drivers = false;

      unused-network-protocols = true;
      firewire-related = true;
      thunderbolt-related = true;
      gnss-related = true;
      esp4-and-esp6 = true;
      xfrm-related = true;
      ipsec-related = true;
      l2tp-related = true;
      legacy-interfaces = true;
      kernel-debugging-related = true;
      cdrom-related = true;
      gpib-related = true;
      dvb-and-tv-receivers = true;
      automotive-related = true;
      rdma-related = true;
      legacy-digital-cameras = true;
      radio-tuners = true;
      remote-controls = true;
    };
  };

  # Max out mmap ASLR entropy (arch ceiling on x86_64 is 32/16) — pure
  # runtime sysctl, no functional dependency, flagged by
  # kernel-hardening-checker as CONFIG_ARCH_MMAP_RND_BITS FAIL (28/8 stock).
  boot.kernel.sysctl = {
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
  };

  # REVERTED (see git history for the shh-generated version that was here
  # briefly): the same profile applied to homeserver's sshd.service showed
  # that ProtectSystem=full / PrivateDevices / PrivateMounts /
  # ProtectKernelTunables leak into every SSH login session's mount
  # namespace, not just the daemon — made /etc, /usr read-only and hid
  # /dev/zfs, /dev/kmsg for shells opened over SSH, including the shell
  # needed to run nixos-rebuild to undo it. Never verified from a fresh
  # SSH session on desktop before this was caught on homeserver — pulling
  # it here too rather than find out the same way. Do not reapply those
  # four directives to sshd without testing from a non-console SSH session
  # first.
}
