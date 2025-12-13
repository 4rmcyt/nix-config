{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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

    initrd.kernelModules = [ "amdgpu" ];

    kernelModules = [ "kvm-amd" ];

    extraModulePackages = [ ];

    # Kernel parameters
    kernelParams = [
      # AMD GPU optimizations (Vega 8 iGPU)
      "amdgpu.gpu_recovery=1"
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.dpm=1" # Dynamic power management for battery life

      # AMD CPU (Zen+ - prioritize battery life over security)
      "amd_pstate=passive" # Passive mode for Zen+ (active is for Zen 3+)
      "microcode.amd_sha_check=off"

      # Security mitigations (disabled for battery life on Zen+)
      "retbleed=off" # Save 14-39% performance
      "spectre_v2=off" # Save 5-15% performance
      "spec_store_bypass_disable=off" # Save 2-5% performance
      "pti=off" # AMD not affected by Meltdown

      # System configuration
      "quiet"
      "splash"
      "loglevel=3"
      "udev.log_level=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];

    # Kernel configuration - CachyOS for better performance on AMD laptop
    kernelPackages = pkgs.linuxPackages_cachyos;
    zfs.package = pkgs.zfs_cachyos;

    # System control parameters
    kernel.sysctl = {
      # Laptop power optimizations
      "kernel.nmi_watchdog" = 0;

      # VM/Memory optimizations for laptop (assume 8-16GB RAM)
      "vm.swappiness" = 60; # Higher for laptops (may have less RAM)
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 20;
      "vm.dirty_background_ratio" = 10;
      "vm.dirty_writeback_centisecs" = 1500; # Longer for battery life

      # Network optimizations
      "net.ipv4.tcp_fastopen" = 3;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
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
  # 4. Power Management
  # =================================================================
  powerManagement = {
    enable = true;
    powertop.enable = true;
    # cpuFreqGovernor = "schedutil"; # Removed, as auto-cpufreq manages this
  };

  # =================================================================
  # 5. Services
  # =================================================================
  services = {
    # Battery optimization
    upower.enable = true;
    # TLP conflicts with auto-cpufreq, using auto-cpufreq instead
    tlp.enable = false;

    ucodenix = {
      enable = true;
      cpuModelId = ./facter.json;
    };

  };

  # =================================================================
  # 6. Networking
  # =================================================================
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp13s0.useDHCP = lib.mkDefault true;

  # =================================================================
  # 7. Platform Configuration
  # =================================================================
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
