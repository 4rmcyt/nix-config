# Desktop host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
  nixosHm = config.modules.nixos.hm;
  nixosWorkstation = config.modules.nixos.workstation;
in {
  configurations.nixos.desktop.module = {pkgs, ...}: {
    imports = [
      nixosBase
      nixosHm
      nixosWorkstation
      ../../../hosts/nixos/desktop
      inputs.noctalia.nixosModules.default
      inputs.mango.nixosModules.mango
      ../../../modules/nix/lix
    ];

    nix.settings = {
      extra-substituters = [
        "https://cache.nixos-cuda.org?priority=1"
        "https://cuda-maintainers.cachix.org?priority=1"
        "https://4rmcyt-desktop.cachix.org?priority=0"
        "https://4rmcyt-gcp.cachix.org?priority=0"
      ];
      extra-trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "4rmcyt-desktop.cachix.org-1:1lj75JVwUuiYqVzG/o2kuUneXV5ydrkFBLuY9b7Nvus="
        "4rmcyt-gcp.cachix.org-1:YeeaTxEm6F3YRsHdEYcggHL3TjrdJrLOfxM6J2YLHwY="
      ];
    };

    programs.mango.enable = true;

    # No UWSM — mango's own HM module (wayland.windowManager.mango.systemd)
    # already binds a mango-session.target to graphical-session.target and
    # imports the environment, so greetd just execs the compositor directly.
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango}/bin/mango";
        user = owner.username;
      };
    };

    # Facter
    facter.reportPath = ../../../hosts/nixos/desktop/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username} = {
      nixpkgs.config.permittedInsecurePackages = ["pnpm-10.29.2" "electron-40.10.5"];
      imports = [
        ../../../home/desktop
        # inputs.stylix.homeModules.stylix
        # inputs.pam-shim.homeModules.default
        inputs.noctalia.homeModules.default
        inputs.mango.hmModules.mango
      ];
    };
  };
}
