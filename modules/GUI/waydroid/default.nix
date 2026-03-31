{
  pkgs,
  lib,
  ...
}: let
  # AMD iGPU (Raphael) — stable by-path symlink, avoids renderD number shifts
  amdRenderNode = "/dev/dri/by-path/pci-0000:10:00.0-render";
in {
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
    "kernel.pid_max" = 65535;
  };

  systemd.services.waydroid-container.serviceConfig = {
    Delegate = lib.mkDefault true;
    CPUAccounting = true;
    MemoryAccounting = true;
    TasksAccounting = true;
    ExecStartPre = lib.mkAfter [
      (pkgs.writeShellScript "waydroid-gpu-fix-pre" ''
        set -e
        PROP_FILE="/var/lib/waydroid/waydroid.prop"

        mkdir -p /var/lib/waydroid
        touch "$PROP_FILE"
        chown root:root "$PROP_FILE"
        chmod 644 "$PROP_FILE"

        set_prop() {
          ${pkgs.gnused}/bin/sed -i "/^$1=/d" "$PROP_FILE"
          echo "$1=$2" >> "$PROP_FILE"
        }

        set_prop ro.hardware.gralloc minigbm_amdgpu
        set_prop ro.hardware.egl mesa
        set_prop gralloc.gbm.device ${amdRenderNode}

        ${pkgs.gnused}/bin/sed -i '/^$/d' "$PROP_FILE"
      '')
    ];
  };
}
