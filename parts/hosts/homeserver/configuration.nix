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
  configurations.nixos.homeserver.module = {pkgs, ...}: {
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

    # nixarr's jellyfin-version -> openapi hash map lags upstream; patched in until it catches up.
    nixarr.nixarr-py.package = pkgs.callPackage
      (pkgs.runCommand "nixarr-py-patched" {} ''
        cp -r ${inputs.nixarr}/nixarr/lib/nixarr-py $out
        chmod -R u+w $out
        substituteInPlace $out/python-deps.nix \
          --replace-fail \
            '"12.0" = "sha256-hu9rbOp+R0tbsjT0Tl639uj0WM5tfYT6uZ6NH0p1zjk=";' \
            '"12.0" = "sha256-hu9rbOp+R0tbsjT0Tl639uj0WM5tfYT6uZ6NH0p1zjk="; "12.1" = "sha256-bMc4br+KUqcmSWn6Y6eG3HRunjevVzur+LNbz6G1Ah0=";'
      '')
      {jellyfin = pkgs.jellyfin;};

    home-manager.users.${owner.username}.imports = [
      ../../../home/homeserver
    ];
  };
}
