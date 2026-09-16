_: {
  nix-mineral = {
    enable = true;

    # /home is a separate ZFS dataset, not a subdir of root; noexec breaks gitstatusd.
    filesystems.normal."/home" = {
      options."bind" = false;
      options."noexec" = false;
    };
    # Separate ZFS dataset too.
    filesystems.normal."/var/log".options."bind" = false;

    # *arr services run scripts from /var/lib; default noexec would block them.
    filesystems.normal."/var/lib" = {
      enable = true;
      options."noexec" = false;
      options."exec" = true;
    };

    # Needed for tailscale exit node/subnet router + podman bridge networking.
    settings.network.ip-forwarding = true;

    # Strict rp_filter drops k3s CNI (cni0) traffic as spoofed.
    settings.network.rp-filter = false;

    # Don't panic-reboot on a driver oops — 3 ZFS pools under active write load.
    settings.kernel.oops-panic = false;

    # Replaces modules/security/hardening.nix's SSH cipher hardening.
    extras.misc.ssh-hardening = true;

    # Blocks su/console root password auth (SSH root login already off).
    extras.system.lock-root = true;

    # TEMPORARY: needed for `shh` strace profiling (double-fork breaks relaxed/admin-only). Revert with the sysctl below.
    settings.system.yama = "none";

    # Real hardware, unused, no downside to blocking the modules.
    kernel-modules.disable = {
      intelme-related = true;
      bluetooth-related = true;

      # Unaudited — leave false. secureblue-additional once broke nfs-server via sunrpc.
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

  boot.kernel.sysctl = {
    # TEMPORARY, tied to settings.system.yama = "none" above — revert together.
    "kernel.yama.ptrace_scope" = 0;

    # Max mmap ASLR entropy.
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;

    # Loose, not strict — k3s CNI bridge routing needs it.
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;

    # k3s apiserver binds 127.0.0.1; cni0 needs route_localnet for ClusterIP DNAT.
    "net.ipv4.conf.default.route_localnet" = 1;
    "net.ipv4.conf.cni0.route_localnet" = 1;
  };
}
