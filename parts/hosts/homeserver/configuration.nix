# Homeserver host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.homeserver.module = {...}: {
    imports = [
      nixosBase
      ../../../hosts/nixos/homeserver
      inputs.nixarr.nixosModules.default
      "${inputs.ephraim-nur}/nixos-modules/lazylibrarian.nix"
    ];

    nixpkgs.overlays = [
      (final: _: {
        ez_setup = final.callPackage "${inputs.ephraim-nur}/pkgs/ez_setup" {};
        iso639-lang = (final.callPackage "${inputs.ephraim-nur}/pkgs/iso639-lang" {}).overrideAttrs (_: {
          meta.description = "A fast, comprehensive, ISO 639 library";
        });
        slskd-api = final.callPackage "${inputs.ephraim-nur}/pkgs/slskd-api" {};
        lazylibrarian = final.callPackage "${inputs.ephraim-nur}/pkgs/lazylibrarian" {
          inherit (final) ez_setup iso639-lang slskd-api;
        };
      })
    ];

    # Facter
    facter.reportPath = ../../../hosts/nixos/homeserver/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username}.imports = [
      ../../../home/homeserver
    ];
  };
}
