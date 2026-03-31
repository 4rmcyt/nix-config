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

  # clipboard sharing between host and waydroid
  environment.systemPackages = [pkgs.wl-clipboard];

  networking.firewall.trustedInterfaces = ["waydroid0"];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    # Fix for waydroid hanging (audio server pid exhaustion)
    "kernel.pid_max" = 65535;
  };

  systemd.services.waydroid-container.serviceConfig = {
    Delegate = lib.mkDefault true;
    CPUAccounting = true;
    MemoryAccounting = true;
    TasksAccounting = true;
  };
}
