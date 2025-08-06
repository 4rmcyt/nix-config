{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "ahci"
    "usb_storage"
    "usbhid"
  ];

  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [
    "kvm-intel"
    "cpufreq_stats"
    "coretemp"
    "fuse"
  ];
  boot.kernelParams = [ "nohibernate" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    vaapiIntel
    vaapiVdpau
    intel-compute-runtime
    intel-ocl
    libvdpau-va-gl
  ];

  hardware.opengl = {
    enable = true;
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  services.fwupd.enable = true;
  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
    devices = [
      { device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315"; }
      { device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345"; }
    ];
  };

  systemd.services.power-tune = {
    description = "Power Management tunings";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.powertop}/bin/powertop --auto-tune
    '';
    serviceConfig.Type = "oneshot";
  };
  systemd.services.lm_sensors = {
    description = "LM Sensors Service";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.lm_sensors}/bin/sensors-detect --auto
    '';
    serviceConfig.Type = "oneshot";
  };

  services.zfs.autoScrub.enable = true;

  services.zfs.zed.settings = {
    ZED_DEBUG_LOG = "/tmp/zed.debug.log";
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
    ZED_EMAIL_OPTS = "@ADDRESS@";

    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;

    ZED_USE_ENCLOSURE_LEDS = true;
    ZED_SCRUB_AFTER_RESILVER = true;
  };
  # this option does not work; will return error
  services.zfs.zed.enableMail = false;
  
  zramSwap.enable = true;

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315-part1";
      fsType = "vfat";
      options = [
        "fmask=0137"
        "dmask=0027"
      ];
    };
  };

}
