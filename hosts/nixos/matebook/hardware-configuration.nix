{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
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

    kernelParams = [
      "amdgpu.gpu_recovery=1"
      # ppfeaturemask=0xffffffff enables OC features, raises idle power on 15W iGPU — omit
      "amdgpu.dpm=1"

      "amd_pstate=passive" # active mode is for Zen 3+
      "microcode.amd_sha_check=off"

      # Mitigations disabled for battery life on Zen+ (AMD not affected by Meltdown/pti)
      "retbleed=off" # saves 14-39% performance
      "spectre_v2=off" # saves 5-15% performance
      "spec_store_bypass_disable=off" # saves 2-5% performance
      "pti=off"

      "pcie_aspm=force" # forces L1 on devices where firmware left it disabled, saves 1-2W
      "pcie_aspm.policy=powersupersave"

      "quiet"
      "splash"
      "loglevel=3"
      "udev.log_level=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];

    kernelPackages = pkgs.linuxKernel.packages.linux_zen;

    kernel.sysctl = {
      "kernel.nmi_watchdog" = 0;

      "vm.swappiness" = 60;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 20;
      "vm.dirty_background_ratio" = 10;
      "vm.dirty_writeback_centisecs" = 1500; # longer for battery life

      "net.ipv4.tcp_fastopen" = 3;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        mesa
      ];
    };

    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = lib.mkDefault true;

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

    firmware = with pkgs; [
      linux-firmware
    ];

    acpilight.enable = true;
  };

  powerManagement.enable = true;

  services = {
    scx = {
      enable = true;
      package = pkgs.scx.full;
      scheduler = "scx_lavd";
      extraArgs = ["--autopilot"];
    };

    upower.enable = true;

    ucodenix = {
      enable = true;
      cpuModelId = ./facter.json;
    };
    fwupd = {
      enable = true;
      extraRemotes = [
        "lvfs-testing"
        "vendor"
      ];
    };
  };

  # nixos-facter-modules force-enables per-interface useDHCP, which flips on global
  # dhcpcd and raced NetworkManager's own client on wlp2s0, crashing dhcpcd with SEGV
  # in dhcp_deconfigure on every sleep/hibernate resume. Same fix as desktop's hardware-configuration.nix.
  facter.detected.dhcp.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce false;
}
