# nix-mineral hardening baseline (inputs.nix-mineral, pinned in flake.nix).
#
# gcp-relay is the simplest host to harden: no podman, no ZFS/Btrfs
# subvolumes, no GUI/games/anti-cheat — just Headscale/DERP/Caddy/fail2ban on
# a single-partition GCE root disk. Starting at nix-mineral's plain defaults
# (no preset) rather than "maximum" since this is the first host running it
# and it's alpha software — layer on more (module blacklist, extras) once
# this boots clean.
{
  nix-mineral = {
    enable = true;

    # This image has no separate /boot mount. `virtualisation.googleComputeImage.efi`
    # is false here (GRUB legacy, see nixpkgs' google-compute-image.nix), so
    # nixpkgs never defines fileSystems."/boot" — nix-mineral's default /boot
    # hardening (self bind-mount with a null device) would otherwise try to
    # create that mount from nothing and fail eval.
    filesystems.normal."/boot".enable = false;
  };
}
