{
  pkgs,
  lib,
  ...
}: {
  virtualisation.waydroid = {
    enable = true;
    # xanmod kernel has no ip_tables module — use nftables variant
    package = pkgs.waydroid-nftables;
  };

  hardware.graphics.enable = lib.mkDefault true;

  # Required for waydroid networking
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    # Fix for waydroid hanging (audio server pid exhaustion)
    "kernel.pid_max" = 65535;
  };
}
