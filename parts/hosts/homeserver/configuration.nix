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

    disabledModules = [];

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
      (final: prev: {
        homepage-dashboard = prev.homepage-dashboard.overrideAttrs (_old: {
          version = "1.13.1";
          src = final.fetchFromGitHub {
            owner = "gethomepage";
            repo = "homepage";
            tag = "v1.13.1";
            hash = "sha256-RKvBzHtxK/VNdSRoJSUiVmckG7jTTH75SEe6aX2xq1E=";
          };
          pnpmDeps = prev.fetchPnpmDeps {
            pname = "homepage-dashboard";
            version = "1.13.1";
            src = final.fetchFromGitHub {
              owner = "gethomepage";
              repo = "homepage";
              tag = "v1.13.1";
              hash = "sha256-RKvBzHtxK/VNdSRoJSUiVmckG7jTTH75SEe6aX2xq1E=";
            };
            pnpm = final.pnpm_10;
            fetcherVersion = 3;
            hash = "sha256-xd7F39WBSAy3ozJjI12XB+oGvijSGHIMYwQhdpaO/l8=";
          };
        });
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
