# Homeserver host definition via Dendritic configurations.nixos option.
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
  configurations.nixos.homeserver.module = {...}: {
    imports = [
      nixosBase
      nixosHm
      nixosWorkstation
      ../../../hosts/nixos/homeserver
      inputs.nixarr.nixosModules.default
      ../../../modules/nix/lix
    ];

    nix.settings = {
      extra-substituters = ["https://4rmcyt-homeserver.cachix.org?priority=0"];
      extra-trusted-public-keys = ["4rmcyt-homeserver.cachix.org-1:QUtDyIxhMJRwispauvcutxugqz0I1PieNprFlIkhBZo="];
    };

    nixpkgs.overlays = [
      (final: prev: let
        version = "1.13.1";
        src = final.fetchFromGitHub {
          owner = "gethomepage";
          repo = "homepage";
          tag = "v${version}";
          hash = "sha256-RKvBzHtxK/VNdSRoJSUiVmckG7jTTH75SEe6aX2xq1E=";
        };
      in {
        homepage-dashboard = prev.homepage-dashboard.overrideAttrs (_old: {
          inherit version src;
          pnpmDeps = prev.fetchPnpmDeps {
            pname = "homepage-dashboard";
            inherit version src;
            pnpm = final.pnpm_10;
            fetcherVersion = 3;
            hash = "sha256-xd7F39WBSAy3ozJjI12XB+oGvijSGHIMYwQhdpaO/l8=";
          };
        });
      })
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

    # Facter
    facter.reportPath = ../../../hosts/nixos/homeserver/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username}.imports = [
      ../../../home/homeserver
    ];
  };
}
