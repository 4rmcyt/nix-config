{
  lib,
  ...
}: {
  virtualisation.waydroid.enable = true;

  # Required kernel modules for waydroid networking
  boot.kernelModules = ["binder_linux"];

  # Allow waydroid to use the GPU
  hardware.graphics.enable = lib.mkDefault true;
}
