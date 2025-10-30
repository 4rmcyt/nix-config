{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # =================================================================
  # 2. Boot Configuration
  # =================================================================
  boot = {
    # Kernel modules for MateBook D14
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];

    initrd.kernelModules = ["amdgpu"];

    kernelModules = ["kvm-amd"];

    extraModulePackages = [];

    # AMD GPU configuration for Ryzen 5 3500U (Vega 8)
    kernelParams = [
      "amdgpu.gpu_recovery=1"
      "amdgpu.ppfeaturemask=0xffffffff"
      "quiet"
      "splash"
      "loglevel=3"
      "udev.log_level=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];

    # Kernel selection
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # =================================================================
  # 3. Hardware Configuration
  # =================================================================
  hardware = {
    # AMD GPU configuration
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        # ROCm for compute/OpenCL
        rocmPackages.clr.icd
        # Video acceleration (VAAPI/VDPAU)
        mesa
      ];
    };

    # AMD CPU configuration
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = lib.mkDefault true;

    # Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    # Firmware packages for WiFi/BT
    firmware = with pkgs; [
      linux-firmware
    ];

    # Backlight control
    acpilight.enable = true;
  };

  # =================================================================
  # 4. Filesystems
  # =================================================================
  # NOTE: Filesystem configuration is managed by disko module
  # See: modules/disko/matebook/default.nix

  # =================================================================
  # 5. Services
  # =================================================================
  services = {
    # Battery optimization
    upower.enable = true;

    # TLP conflicts with auto-cpufreq, using auto-cpufreq instead
    tlp.enable = false;
  };

  # =================================================================
  # 6. Power Management
  # =================================================================
  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "schedutil";
  };

  # =================================================================
  # 7. Networking
  # =================================================================
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp13s0.useDHCP = lib.mkDefault true;

  # =================================================================
  # 8. Platform Configuration
  # =================================================================
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
