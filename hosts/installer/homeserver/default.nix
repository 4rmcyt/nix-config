{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Auto-select latest ZFS-compatible kernel
  zfsCompatibleKernelPackages =
    lib.filterAttrs (
      name: kernelPackages:
        (builtins.match "linux_[0-9]+_[0-9]+" name)
        != null
        && (builtins.tryEval kernelPackages).success
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
    )
    pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    ../../../modules/users/zeev
    ../../../modules/disko/homeserver
  ];

  # =================================================================
  # Nix Settings
  # =================================================================
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = lib.mkForce [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # =================================================================
  # Boot Configuration
  # =================================================================
  boot = {
    kernelPackages = latestKernelPackage;
    supportedFilesystems = ["btrfs" "ntfs" "zfs"];
  };

  # =================================================================
  # ISO Configuration
  # =================================================================
  image.baseName = "nixos-installer-homeserver";

  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    squashfsCompression = "zstd -Xcompression-level 6";
  };

  # =================================================================
  # Networking
  # =================================================================
  networking = {
    hostName = "nixos-installer";
    hostId = "deadbeef";
    networkmanager.enable = true;
    wireless.enable = false;
  };

  # =================================================================
  # Services
  # =================================================================
  services = {
    # Enable SSH for remote installation
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "yes";
      };
    };
  };

  # =================================================================
  # Users
  # =================================================================
  users.users.nixos = {
    initialHashedPassword = lib.mkForce null;
    initialPassword = lib.mkForce "nixos";
    extraGroups = ["wheel" "networkmanager"];
  };

  # =================================================================
  # Environment
  # =================================================================
  environment.systemPackages = with pkgs; [
    # Essentials
    git
    helix
    vim

    # System utilities
    btop
    disko
    neofetch
    pciutils
    usbutils

    # Disk utilities
    cryptsetup
    dosfstools
    e2fsprogs
    ntfs3g
    parted
    zfs
  ];

  # =================================================================
  # System Configuration
  # =================================================================
  system.stateVersion = "25.05";
}
