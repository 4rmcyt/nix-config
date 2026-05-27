{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/options

    ./headscale.nix
    ./headplane.nix
    ./caddy.nix
    ./crowdsec.nix
    ./fail2ban.nix
    ./monitoring.nix
  ];

  # =================================================================
  # System
  # =================================================================
  networking.hostName = "oracle-relay";
  time.timeZone = config.my.defaults.timezone;
  i18n.defaultLocale = config.my.defaults.locale;

  boot.loader.grub.enable = lib.mkDefault true;
  boot.loader.grub.device = lib.mkDefault "/dev/sda";

  # =================================================================
  # Nix
  # =================================================================
  nix.settings = {
    cores = 2;
    max-jobs = "auto";
    trusted-users = ["root" "@wheel"];
  };

  # =================================================================
  # Sops
  # =================================================================
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "/root/.config/sops/age/keys.txt";
  };

  # =================================================================
  # Networking & firewall
  # =================================================================
  networking = {
    useNetworkd = true;
    useDHCP = lib.mkDefault false;
  };

  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
      80 # Caddy HTTP (ACME redirect)
      443 # Caddy HTTPS
    ];
    # headscale STUN (embedded DERP)
    allowedUDPPorts = [3478];
  };

  # =================================================================
  # SSH
  # =================================================================
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
    };
  };

  # =================================================================
  # User
  # =================================================================
  users.users.${config.my.defaults.user} = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7QtXHGjNp8yxRIbMwb605n3fqFoq+PxOzbq6i2dEr6YDIKqajRNBHiEHjV3z7ABLpi2cfHPcw8Cgg/esD/98uGM9lKxdCev1VEubmsTmZAuDBz04p/S/yB7UBc5muHJLkzFNjlwMYP3x3JAr9if3nmrAZNh5qOrymZndJ7h9IT9WZNvvgFW2I+S/Ugi7eq5yRIDm5S7ADW/9wThfvG8ZqhMXDvvKXHJYx/O8D8th1ffN5l8pAJZkiV21zW0pu4od4iAaVM531H22FORAq6PbHAwr5u8a0jBlTqkwlo9x3O+hdKBVhW1XQfeRqg69lJtmUUFipl4viBj9Rpz+gtv4BjKL9ChCgqVLMLPe/bviRjqx3bvC2I78H0N51SvAh0QOj1ByAk3Xvj3R2qwk7LAmLgSlPoOsGpkbILhudF7KLJ/Uh2kpZI3NOcYdy9TYMws97zCvevgqw07HEEOydYpPB4+ml8Zzb+Tcw0U7yLRWMAB1VP1WE1vM0U6XQa7CRhcU="
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx"
  ];

  security.sudo.wheelNeedsPassword = false;

  # =================================================================
  # Packages
  # =================================================================
  environment.systemPackages = with pkgs; [
    curl
    htop
    jq
    nftables
    tcpdump
    vim
  ];

  # =================================================================
  # State version
  # =================================================================
  system.stateVersion = "25.11";
}
