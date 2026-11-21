{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
  nixosHm = config.modules.nixos.hm;
  nixosBareMetal = config.modules.nixos.bareMetal;
  nixosNixMineral = config.modules.nixos.nixMineral;
in {
  configurations.nixos.homeserver.module = {...}: {
    imports = [
      nixosBase
      nixosHm
      nixosBareMetal
      nixosNixMineral
      ../../../hosts/nixos/homeserver
      inputs.nixarr.nixosModules.default
      ../../../modules/nix/lix
    ];

    nix.settings = import ../../../lib/cachix.nix "homeserver" "QUtDyIxhMJRwispauvcutxugqz0I1PieNprFlIkhBZo=";

    home-manager.users.${owner.username}.imports = [
      ../../../home/homeserver
    ];
  };
}
