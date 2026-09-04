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
  hmWorkstation = config.modules.homeManager.workstation;
in {
  configurations.nixos.desktop.module = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      nixosBase
      nixosHm
      nixosWorkstation
      ../../../hosts/nixos/desktop
      inputs.noctalia.nixosModules.default
      ../../../modules/nix/lix
    ];

    nix.settings = let
      cachix = import ../../../lib/cachix.nix;
      own = cachix "desktop" "1lj75JVwUuiYqVzG/o2kuUneXV5ydrkFBLuY9b7Nvus=";
      gcp = cachix "gcp" "YeeaTxEm6F3YRsHdEYcggHL3TjrdJrLOfxM6J2YLHwY=";
    in {
      extra-substituters =
        [
          "https://cache.nixos-cuda.org?priority=1"
          "https://cuda-maintainers.cachix.org?priority=1"
        ]
        ++ own.extra-substituters
        ++ gcp.extra-substituters;
      extra-trusted-public-keys =
        [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        ]
        ++ own.extra-trusted-public-keys
        ++ gcp.extra-trusted-public-keys;
    };

    # `programs.mango` is nixpkgs' own module now (portal + systemPackages
    # wiring only — packages the stable v0.16.1 release, which has no HDR).
    # We no longer import inputs.mango.nixosModules.mango — it duplicate-
    # declared the same `programs.mango.enable` option nixpkgs now ships,
    # which errors at eval time (two non-identical mkEnableOption
    # declarations of the same option path don't merge). Point `package` at
    # our own flake's build so systemPackages/portals match the binary
    # greetd actually execs below.
    programs.mango = {
      enable = true;
      package = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;
    };

    # No UWSM — mango's own HM module (wayland.windowManager.mango.systemd)
    # already binds a mango-session.target to graphical-session.target and
    # imports the environment, so greetd just execs the compositor directly.
    #
    # WLR_RENDERER=vulkan must be in mango's own process environment before
    # wlroots picks a renderer backend, which happens before mango ever
    # reads config.conf — so `env=WLR_RENDERER,vulkan` inside config.conf
    # (modules/WM/mango/default.nix) is too late and silently has no effect
    # (confirmed: `mmsg get monitor` still reports is_hdr:false with that
    # config-file directive alone). It has to be set here, on the actual
    # exec that starts mango.
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "env WLR_RENDERER=vulkan ${inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango}/bin/mango";
        user = owner.username;
      };
    };

    facter.reportPath = ../../../hosts/nixos + "/${config.networking.hostName}/facter.json";

    home-manager.users.${owner.username} = {
      nixpkgs.config.permittedInsecurePackages = ["pnpm-10.29.2" "electron-40.10.5"];
      imports = [
        hmWorkstation
        ../../../home/desktop
        inputs.noctalia.homeModules.default
        inputs.mango.hmModules.mango
      ];
    };
  };
}
