{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
  nixosHm = config.modules.nixos.hm;
  nixosBareMetal = config.modules.nixos.bareMetal;
  nixosWorkstationGui = config.modules.nixos.workstationGui;
  nixosNixMineral = config.modules.nixos.nixMineral;
  hmWorkstation = config.modules.homeManager.workstation;
in {
  configurations.nixos.desktop.module = {pkgs, ...}: {
    imports = [
      nixosBase
      nixosHm
      nixosBareMetal
      nixosWorkstationGui
      nixosNixMineral
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
          # cuda-maintainers.cachix.org migrated here; old URL 404s the substituter handshake.
          "https://cache.nixos-cuda.org?priority=1"
        ]
        ++ own.extra-substituters
        ++ gcp.extra-substituters;
      extra-trusted-public-keys =
        [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ]
        ++ own.extra-trusted-public-keys
        ++ gcp.extra-trusted-public-keys;
    };

    # Not importing inputs.mango.nixosModules.mango: it duplicate-declares the same
    # `programs.mango.enable` nixpkgs now ships, which errors at eval time. `package`
    # points at our own flake's build so it matches the binary greetd execs below.
    programs.mango = {
      enable = true;
      package = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;
    };

    # WLR_RENDERER=vulkan must be in mango's process environment before wlroots picks a
    # renderer backend, which happens before mango ever reads config.conf — setting it
    # via config.conf (modules/WM/mango/default.nix) is too late and silently no-ops.
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "env WLR_RENDERER=vulkan ${inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango}/bin/mango";
        user = owner.username;
      };
    };

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
