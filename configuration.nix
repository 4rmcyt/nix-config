{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  user-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyieBFROVPWmH3iC2ZAE+5zofMd6mnunBzfObEwMgFx";
  user-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7QtXHGjNp8yxRIbMwb605n3fqFoq+PxOzbq6i2dEr6YDIKqajRNBHiEHjV3z7ABLpi2cfHPcw8Cgg/esD/98uGM9lKxdCev1VEubmsTmZAuDBz04p/S/yB7UBc5muHJLkzFNjlwMYP3x3JAr9if3nmrAZNh5qOrymZndJ7h9IT9WZNvvgFW2I+S/Ugi7eq5yRIDm5S7ADW/9wThfvG8ZqhMXDvvKXHJYx/O8D8th1ffN5l8pAJZkiV21zW0pu4od4iAaVM531H22FORAq6PbHAwr5u8a0jBlTqkwlo9x3O+hdKBVhW1XQfeRqg69lJtmUUFipl4viBj9Rpz+gtv4BjKL9ChCgqVLMLPe/bviRjqx3bvC2I78H0N51SvAh0QOj1ByAk3Xvj3R2qwk7LAmLgSlPoOsGpkbILhudF7KLJ/Uh2kpZI3NOcYdy9TYMws97zCvevgqw07HEEOydYpPB4+ml8Zzb+Tcw0U7yLRWMAB1VP1WE1vM0U6XQa7CRhcU=";
  user-keys = [ user-ed25519 user-rsa ];

  system-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJV+/pct8PNZhUqvnflYY5auIE1zTl3sPtCfVynTnajN";
  system-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCRCKSMfoxE3uVaNDemMYYls0yoA4h4so6bVG0E+4XPa0ZEVLJYFT+tvsNdyxRmrIDLv745JCVHtv41t5qUjnafl/uBnl5dggt6W3Kkl1iZ6nyb8lgChp9egyXruEXekqTtYC0AQVjB7yC2GV5rS4R4FYY8pNYzzmmFjRT/IM6JIGn3GZubMv4GLc/xCnXZPNluNLJPxQ8oML5IjHzYFDXzDvlgB8i6ugNqE8zqIMxSFFXIrhAev41wcOE0lSjSE9gb3+HTyAmJtWCRcSyPHmKeugytNca6X3KtoU5tO1MrSlIQn8wfJkJWe/2zXueA/e4uENgS0DBVWuNXLcojYBxHFXF2OtR7R5qpVw0hcfOJkC9+EjTcRTf4MnzGfQUrDeiZerf02Dp9mvN4IBMc4nDL2h81YZcfucDd76BUkei0ppI6UbeEEFgOz1zQAggCY0I8HLZZjccK+zJzAo3JoFFbhNjX0iEWPEbcHxR3FQRDMnis0MV1gqHj8wtbWJPtqMrcAjjMu+aWfvzedEH0SDvOD6AppD2IeNVrVUJJlSk3zcX2gYfhrXEbgKG3PWxEvVnTRPk2PR+73j8ms9dONwrugKZGwMmO4c2xVWTXiI4qPfqxsBK7v7dP3f+hkx3cB34cpwtDEEBuR8hqjae4T0mJhJkcMWvDixEUxrDIJ7efkQ==";
  system-keys = [ system-ed25519 system-rsa ];

  server-keys = system-keys ++ user-keys;
in
{
  imports = [
    ./hardware-configuration.nix
    ./users
    ./networking
    ./modules/base
    ./modules/sops
  ];

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      download-buffer-size = 500000000;
      cores = 0;
      show-trace = true;
    };
    registry.nixpkgs = {
      from = {
        id = "nixpkgs";
        type = "indirect";
      };
      flake = inputs.nixpkgs;
    };
  };

  security.sudo.execWheelOnly = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };


  environment.systemPackages = with pkgs; [
    zsh git neovim direnv pass vim wget curl jq coreutils gawk gnugrep
    iproute2 mc htop btop lsof age sops ssh-to-age openssh wireguard-tools
    apacheHttpd zsh-powerlevel10k meslo-lgs-nf yamllint nix-index iotop
    tuptime smartmontools fzf ffmpeg nmap trash-cli zip unar unzip p7zip
    calibre go
  ];

  services = {
    openssh = {
      enable = true;
      hostKeys = [
        {
          type = "ed25519";
          path = config.sops.secrets.ssh_host_ed25519_key.path;
        }
        {
          type = "rsa";
          bits = 4096;
          path = config.sops.secrets.ssh_host_rsa_key.path;
        }
      ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
      extraConfig = ''
        Match user git
          AllowTcpForwarding no
          AllowAgentForwarding no
          PasswordAuthentication no
          PermitTTY no
          X11Forwarding no
      '';
    };
    vscode-server.enable = true;
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh.enable = true;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.zeev = import ./home-manager;
  };
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}
