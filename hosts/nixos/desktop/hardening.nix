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
