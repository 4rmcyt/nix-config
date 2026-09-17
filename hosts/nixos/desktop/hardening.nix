# No preset applied: desktop's Steam/Proton/GameConqueror/waydroid/libvirt/podman stack
# needs per-option overrides below rather than nix-mineral's blanket defaults.
{
  nix-mineral = {
    enable = true;

    # /var/log is a separate Btrfs subvolume, not a subdir of root — nix-mineral's
    # default self bind-mount assumes the latter and breaks stage-2 activation otherwise.
    filesystems.normal."/var/log".options."bind" = false;

    # Steam/Proton, Wine prefixes, and AppImages all exec binaries out of $HOME.
    filesystems.normal."/home" = {
      options."bind" = false;
      options."noexec" = false;
    };

    # /var/lib isn't a separate subvolume, so nix-mineral's default noexec=true
    # applies here and breaks podman containers execing binaries from image layers.
    filesystems.normal."/var/lib" = {
      enable = true;
      options."noexec" = false;
      options."exec" = true;
    };

    # podman bridge + libvirt NAT (virbr0) both need forwarding; nix-mineral's
    # default force-disables it at mkOverride 900, above mkDefault from other modules.
    settings.network.ip-forwarding = true;

    # Dual-homed (wired enp12s0 + wifi wlp13s0, both with active default routes) —
    # strict rp_filter drops the non-preferred interface's return traffic.
    settings.network.rp-filter = false;

    # nix-mineral's "restrict" default disables accept_ra_pinfo, breaking IPv6 SLAAC.
    settings.network.router-advertisements = "on";

    # Needed for Wine/Proton (Steam), Java, and AppImages.
    settings.kernel.binfmt-misc = true;

    # Default auto-true on kernel >=6.17 adds red-zoning overhead; no debugging need here.
    settings.kernel.slab-debug = false;

    # Needed for native (non-Proton) 32-bit Steam games.
    settings.kernel.vdso32 = true;

    # Gaming box, not multi-tenant — keep SMT on, still applies standard mitigations.
    settings.kernel.cpu-mitigations = "smt-on";

    # DHCP reservations (my.network.hosts.desktop_lan/desktop_wifi) are keyed to the
    # real hardware MAC — NetworkManager randomization would break them.
    settings.network.random-mac = false;

    # Default (1) is too low for SLAAC + privacy-extension temp addresses running together.
    settings.network.max-addresses = 8;

    # Reproduced live: with strict arp_ignore/arp_filter (both default true), the
    # dual-homed enp12s0/wlp13s0 setup black-holed WAN traffic on whichever
    # interface lost the ARP race.
    settings.network.arp = {
      ignore = "none";
      filter = false;
    };

    # Needed for 32-bit Steam games/libraries.
    settings.system.multilib = true;

    # Default "ptrace" restricts mmap/mprotect for every process, not just debuggers —
    # breaks JIT compilers, Wine, and dynamic linkers.
    settings.system.proc-mem-force = "none";

    # Want core dumps for debugging game/Proton crashes.
    settings.debug.coredump = true;

    # Default pulls Kicksecure's AutoEnable=false, leaving the BT headset off after boot.
    settings.etc.kicksecure-bluetooth = false;

    # Default panics the kernel on any oops; a flaky GPU/wine oops shouldn't force
    # an unclean reboot.
    settings.kernel.oops-panic = false;

    # CRITICAL: nix-mineral's "restricted" default is applied via mkForce and would
    # silently override modules/gaming's ptrace_scope=0 (needed by GameConqueror/
    # scanmem) — verify after rebuild with `sysctl kernel.yama.ptrace_scope` == 0.
    settings.system.yama = "none";

    # Disables X11/TCP/agent forwarding; desktop doesn't tunnel through its own sshd.
    extras.misc.ssh-hardening = true;

    # Closes the su/console root password-login path that PermitRootLogin=no doesn't
    # cover; zeev's sudo password is unaffected.
    extras.system.lock-root = true;

    # Audited against actual hardware/usage on this host (lspci/lsusb/lsblk/ip link,
    # repo grep), not left at nix-mineral's blanket-true default.
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

  # Max out mmap ASLR entropy (x86_64 ceiling is 32/16); flagged by
  # kernel-hardening-checker as CONFIG_ARCH_MMAP_RND_BITS FAIL at stock.
  boot.kernel.sysctl = {
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
  };

  # Do not add sshd.service ProtectSystem=full/PrivateDevices/PrivateMounts/
  # ProtectKernelTunables: on homeserver these hardened the daemon but also
  # leaked into every SSH session's mount namespace, locking out nixos-rebuild.
}
