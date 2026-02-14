# Homeserver host definition via Dendritic configurations.nixos option.
{ config, inputs, ... }:
let
  owner = config.meta.owner;
  nixosBase = config.modules.nixos.base;
in
{
  configurations.nixos.homeserver.module = { ... }: {
    imports = [
      nixosBase
      ../../../hosts/nixos/homeserver
      inputs.nixarr.nixosModules.default
    ];

    # Facter
    facter.reportPath = ../../../hosts/nixos/homeserver/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username}.imports = [
      ../../../home/homeserver
    ];
  };
}
