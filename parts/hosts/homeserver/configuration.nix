# Homeserver host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
  nixosHm = config.modules.nixos.hm;
  nixosBareMetal = config.modules.nixos.bareMetal;
in {
  configurations.nixos.homeserver.module = {...}: {
    imports = [
      nixosBase
      nixosHm
      nixosBareMetal
      ../../../hosts/nixos/homeserver
      inputs.nixarr.nixosModules.default
      ../../../modules/nix/lix
    ];

    nix.settings = import ../../../lib/cachix.nix "homeserver" "QUtDyIxhMJRwispauvcutxugqz0I1PieNprFlIkhBZo=";

    nixpkgs.overlays = [
      (_final: prev: {
        inherit
          (inputs.arr-packages.packages.${prev.system})
          sonarr
          radarr
          prowlarr
          bazarr
          jellyfin
          jellyfin-web
          ;
      })
    ];

    home-manager.users.${owner.username}.imports = [
      ../../../home/homeserver
    ];
  };
}
