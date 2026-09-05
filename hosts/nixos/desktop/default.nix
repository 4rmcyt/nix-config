{
  pkgs,
  config,
  lib,
  ...
}: {
  my.nodeExporter.enable = true;

  my.alloyClient.enable = true;

  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/base/logging/desktop.nix
    ../../../modules/disko/desktop
    ../../../modules/fonts
    ../../../modules/options

    # Monitoring
    ../../../modules/monitoring/node-exporter-client.nix
    ../../../modules/monitoring/alloy-client.nix

    # Features and roles
    # GUI/{chrome,flatpak,kdeconnect,nemo} + networking/nfs-client come from
    # modules.nixos.workstationGui (parts/workstation.nix).
    ../../../modules/containers
    ../../../modules/gaming
    ../../../modules/networking/dnssec
    ../../../modules/networking/nut-client
    ../../../modules/networking/ssh

    # Users & GUI
    ../../../modules/GUI/coolercontrol
    ../../../modules/GUI/virt-manager
    ../../../modules/GUI/waydroid
    ../../../modules/TUI/tty.nix
    ../../../modules/users/zeev
  ];

  sops = {
    secrets = {
      tailscale_auth_key = {
        sopsFile = ../../../secrets/tailscale-desktop.yaml;
      };
      git_access_token = {
        sopsFile = ../../../secrets/common.yaml;
        key = "git_access_token";
        owner = "root";
      };
      codeberg_access_token = {
        sopsFile = ../../../secrets/common.yaml;
        key = "codeberg_access_token";
        owner = "root";
      };
      gemini_api_key = {
        sopsFile = ../../../secrets/common.yaml;
        key = "gemini_api_key";
        owner = "zeev";
      };
    };

    age.keyFile = "/root/.config/sops/age/keys.txt";
  };

  nix.settings = {
    cores = 0;
    max-jobs = "auto";
    extra-system-features = [
      "big-parallel"
      "kvm"
    ];
    # "root" + "@wheel" already come from parts/shared-nixos-settings.nix
    trusted-users = ["nix-builder"];
  };

  environment = {
    sessionVariables = lib.mkBefore {
      XCURSOR_THEME = "breeze_cursors";
      XCURSOR_SIZE = "24";

      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";

      # Add home-manager and flatpak paths for fonts and icons in all sessions (including TTY)
      XDG_DATA_DIRS = lib.mkAfter [
        "$HOME/.nix-profile/share"
        "$HOME/.local/share/flatpak/exports/share"
        "/var/lib/flatpak/exports/share"
      ];
    };

    shells = lib.mkBefore (with pkgs; [zsh]);

    systemPackages = with pkgs; [
      # Dev workstation tools (not on all hosts)
      ansible
      awscli2
      s3cmd
      opentofu
      terraform
      gradle
      kotlin
      ktlint
      prometheus # promtool linter
      iw
    ];
  };

  fonts = {
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      useEmbeddedBitmaps = true;
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "Fira Code"
        ];
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
        emoji = ["Noto Color Emoji"];
      };
    };
    packages = with pkgs;
      [
        maple-mono.NF
        font-awesome
        noto-fonts
        noto-fonts-color-emoji
      ]
      ++ (builtins.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts));
  };

  networking = {
    dnssec = {
      enable = true;
      profileId = config.my.defaults.nextdnsProfileId;
    };
    enableIPv6 = true;
    interfaces.enp12s0.wakeOnLan.enable = true;
  };

  # kvm-amd nested virtualization: needed so guest VMs (e.g. the OpenStack
  # lab VM) can run their own KVM-accelerated Nova compute nodes.
  boot.extraModprobeConfig = "options kvm-amd nested=1";

  programs.nix-ld.enable = true;

  programs.solaar = {
    enable = true;
    userService.enable = true;
  };

  security.pam.services.greetd.enableGnomeKeyring = true;

  environment.etc."xdg/autostart/gnome-keyring-secrets.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Secret Storage Service
    Hidden=true
  '';

  services = {
    gnome.gnome-keyring.enable = true;

    openssh.enable = true;

    tailscale = {
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = [
        "--accept-routes"
        "--accept-dns=true"
        "--reset"
        "--login-server=https://hs.${config.my.defaults.domain}"
      ];
      extraSetFlags = ["--operator=${config.my.defaults.user}"];
    };
  };

  users = {
    groups = {
      git = {};
      plugdev = {};
      prometheus = {};
      nix-builder = {};
    };

    users = {
      git = {
        createHome = true;
        description = "Git user";
        group = "git";
        home = "/var/lib/git";
        isSystemUser = true;
        shell = pkgs.bash;
      };

      prometheus = {
        description = "Prometheus daemon user";
        group = "prometheus";
        isSystemUser = true;
      };

      nix-builder = {
        isSystemUser = true;
        group = "nix-builder";
        description = "Nix remote builder user";
        home = "/var/lib/nix-builder";
        createHome = true;
        shell = pkgs.bash;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ6N/kA0Cx1Swre7mQzWvqxL2o4TvD3l0hrAiNr0Qkcp nix-builder@homeserver"
        ];
      };

      zeev.shell = lib.mkForce pkgs.zsh;
    };
  };

  # No battery on desktop — keep UPower running (wireplumber needs it for BT headset battery)
  # but disable all power management polling since there's no battery
  services.upower = {
    enable = true;
    ignoreLid = true;
    noPollBatteries = true;
  };

  # Cups resolves "localhost" to both 127.0.0.1 and ::1
  services.printing.listenAddresses = ["127.0.0.1:631" "[::1]:631"];

  security.sudo.extraConfig = "Defaults lecture = never";
}
