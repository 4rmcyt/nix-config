{lib, ...}: {
  virtualisation.waydroid.enable = true;

  hardware.graphics.enable = lib.mkDefault true;

  # iptables legacy modules required by waydroid networking (xanmod has these as =m)
  boot.kernelModules = ["ip_tables" "ip6_tables" "iptable_nat" "iptable_filter"];

  # Required for waydroid networking
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    # Fix for waydroid hanging (audio server pid exhaustion)
    "kernel.pid_max" = 65535;
  };
}
