{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    ../../../modules/users/zeev
    ../../../modules/disko/matebook
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
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce ["btrfs" "ntfs"];
  };

  # =================================================================
  # ISO Configuration
  # =================================================================
  image.fileName = lib.mkOverride 0 "nixos-installer-matebook.iso";
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

    # Audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  # =================================================================
  # Users
  # =================================================================
  users.users.nixos = {
    initialHashedPassword = lib.mkForce null;
    initialPassword = lib.mkForce "nixos";
    extraGroups = ["wheel" "networkmanager" "video" "audio"];
  };

  # =================================================================
  # Environment
  # =================================================================
  environment.systemPackages = with pkgs; [
    # Installation tools
    calamares-nixos
    gparted

    # Essentials
    git
    helix
    vim

    # File management
    file-roller
    nautilus

    # Browsers
    firefox

    # Terminal
    kitty

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

    # Laptop-specific
    acpi
    brightnessctl
    powertop
  ];

  # =================================================================
  # System Configuration
  # =================================================================
  system.stateVersion = "25.05";
}
