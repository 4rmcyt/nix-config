# modules/base/server.nix

{ pkgs, ... }:
{
  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Nix daemon settings
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "zeev" ];
      auto-optimise-store = true;
      warn-dirty = false;
      cores = 4;
      show-trace = true;
      download-buffer-size = 1073741824; # 1 GiB
      max-jobs = 4;
    };
    optimise.automatic = true;
  };

  # Essential system-wide packages for administration and monitoring
  environment.systemPackages = with pkgs; [
    # Core utils
    coreutils
    iproute2
    # Monitoring
    htop
    btop
    lsof
    iotop
    tuptime
    smartmontools
    # System admin
    git # Keep git system-wide for things like nix flake commands as root
    wget
    curl
    openssl
    fwupd
    cachix
    nmap
    wireguard-tools
    pinentry-tty
  ];

  services.nextdns = {
    enable = true;
    arguments = [ "-profile" "2bffa2" "-cache-size" "10MB" "--report-client-info" ];
  };
  services.vscode-server.enable = true;

  # System-wide programs and security
  programs = {
    nix-ld.enable = false; # Set to false, as per original config
    nix-index.enable = true; # Enable the daemon system-wide
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
      enableSSHSupport = true;
    };
  };
  security.sudo.execWheelOnly = true;

  # System state version
  system.stateVersion = "25.05";
}
