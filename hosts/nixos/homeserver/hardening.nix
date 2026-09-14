# nix-mineral hardening baseline (inputs.nix-mineral, tracks main in flake.nix).
# Replaces modules/security/hardening.nix (deleted) — SSH ciphers now come
# from extras.misc.ssh-hardening below; the crowdsec/prometheus systemd
# hardening that used to live there moved into their own modules
# (modules/security/crowdsec, modules/monitoring/prometheus.nix).
{
  nix-mineral = {
    enable = true;

    # /home and /var/log are real, separate ZFS datasets (own mountpoint,
    # see modules/disko/homeserver), not subdirectories of the root dataset.
    # nix-mineral's default self bind-mount ("bind" = true) assumes the
    # opposite (a single-partition layout where hardened paths are bound
    # onto themselves) and breaks stage-2 activation on a real separate
    # mount — same class of issue as Btrfs subvolumes, see nix-mineral's
    # own FAQ / issue #11. /var, /root, /tmp, /var/tmp, /etc, /srv all live
    # inside the "root" zfs dataset ("/"), so the default is correct there.
    # /boot is a real ESP mount too, but nix-mineral already ships
    # bind = false for it by default.
    #
    # noexec off too: zeev has a full interactive shell here (zsh/p10k),
    # and gitstatusd (powerlevel10k's git-status daemon) caches its binary
    # at ~/.cache/gitstatus/gitstatusd-linux-x86_64 — under noexec that's
    # just a silent "gitstatus failed to initialize" at every login, no
    # exec-denied message pointing at the actual cause. Confirmed live:
    # `mount` showed /home as noexec, the binary sat right there refusing
    # to run.
    filesystems.normal."/home" = {
      options."bind" = false;
      options."noexec" = false;
    };
    filesystems.normal."/var/log".options."bind" = false;

    # Native *arr services (sonarr/radarr/prowlarr/bazarr) keep state and any
    # custom scripts/Recyclarr connect-hooks under /var/lib/<service>, which
    # is on the same "root" dataset as /var — nix-mineral's default noexec on
    # /var would otherwise reach them. Same override nix-mineral's own
    # compatibility preset uses for this exact reason.
    filesystems.normal."/var/lib" = {
      enable = true;
      options."noexec" = false;
      options."exec" = true;
    };

    # Homeserver is a Tailscale exit node + subnet router
    # (advertiseExitNode / advertiseRoutes in ./default.nix) — the tailscale
    # module forces IP forwarding on via mkDefault, but nix-mineral's own
    # default (false) disables it at a higher override priority (900 vs
    # mkDefault's 1000), which would actually break exit-node/subnet-router
    # routing here, not just in theory. Podman's bridge networking (heavily
    # used here — home-assistant, seerr, lazylibrarian, komf, byparr,
    # dispatcharr, kapowarr) needs it too.
    settings.network.ip-forwarding = true;

    # Default panics the kernel on any oops (boot.kernelParams "oops=panic").
    # Too aggressive for a multi-service box with 3 ZFS pools under active
    # write load — a single flaky driver oops shouldn't force an unclean
    # reboot. See docs/Infrastructure.md ZFS Safety Rules.
    settings.kernel.oops-panic = false;

    # Replaces the SSH cipher/auth hardening that used to come from
    # modules/security/hardening.nix. Non-overlapping SSH settings
    # (AllowUsers, ...) stay inline in ./default.nix.
    extras.misc.ssh-hardening = true;

    # PermitRootLogin=no already blocks SSH root login; this closes the
    # remaining path (su/console password auth as root) by making the
    # password hash unmatchable. zeev's sudo still needs its own password
    # (security.sudo.wheelNeedsPassword), unaffected.
    extras.system.lock-root = true;

    # Real Intel ME hardware here, never touched over any network path we
    # manage — pure attack-surface reduction, no downside.
    #
    # hardware.bluetooth.enable is already false
    # (hosts/nixos/homeserver/hardware-configuration.nix) — bluetooth is
    # already unused, this just blocks the kernel modules too instead of
    # only disabling the service.
    #
    # Every option below this point except intelme-related/bluetooth-related
    # is explicitly forced to false. Touching `kernel-modules.disable` at
    # all pulls in cynicsketch/nix-mineral's separate secureblue-derived
    # combo set (kernel-modules/combos/secureblue-disable.nix) — ~20 more
    # module-blacklist options that default to `true` on their own,
    # independent of anything we set here. One of them
    # (`secureblue-additional`) blacklists `sunrpc`, which NFS (nfsd,
    # rpc_pipefs, lockd) depends on entirely — confirmed live: this broke
    # nfs-server.service outright ("unknown filesystem type 'nfsd'",
    # modprobe resolving nfsd/sunrpc to nix-mineral's disabled-module-alert
    # stub) the first time homeserver actually rebooted into a generation
    # with this config. `unused-filesystems` likely also covers nfsd
    # itself. Never audited these before enabling — not doing that again;
    # explicit false for every one we don't specifically want.
    kernel-modules.disable = {
      intelme-related = true;
      bluetooth-related = true;

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
}
