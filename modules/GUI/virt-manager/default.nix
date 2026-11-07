{pkgs, ...}: {
  programs.virt-manager.enable = true;

  # Without this, `virsh`/`virt-manager` default to qemu:///session (per-user,
  # no domains visible) instead of qemu:///system, even for libvirtd-group members.
  environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";

  virtualisation = {
    podman.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        vhostUserPackages = with pkgs; [virtiofsd];
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # Clipboard sharing between host desktop and SPICE VMs (e.g. win11).
  services.spice-vdagentd.enable = true;

  # VirtIO drivers ISO for Windows guests.
  environment.systemPackages = [pkgs.virtio-win];
}
