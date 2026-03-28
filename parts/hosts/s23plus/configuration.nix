# Galaxy S23+ nix-on-droid configuration.
# Deploy: nix-on-droid switch --flake .#s23plus --impure
# Note: tailscale daemon runs as Android app — CLI available via HM packages.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
in {
  configurations.nixOnDroid.s23plus.module = {pkgs, lib, ...}: {
    time.timeZone = owner.timezone;
    system.stateVersion = "24.05";

    # nix 2.31.3+ broke nix-env on Android — pin to 2.30
    nix.package = lib.mkForce pkgs.nixVersions.nix_2_30;

    user.shell = "${pkgs.zsh}/bin/zsh";

    # Nix daemon settings
    nix.extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      connect-timeout = 10
      eval-cache = true
      auto-optimise-store = true
      max-jobs = 4
      cores = 4
      min-free = 1073741824
      max-free = 3221225472
      warn-dirty = false
    '';

    nix.substituters = [
      "https://4rmcyt.cachix.org"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    nix.trustedPublicKeys = [
      "4rmcyt.cachix.org-1:yHVDqXs6TDmfSOuPbl4gcfomDK9gzTmK8FabfHLi+d8="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    # Home Manager integration
    home-manager = {
      useGlobalPkgs = true;
      config = {
        imports = [
          ../../../home/s23plus
        ];
      };
      extraSpecialArgs = {inherit inputs;};
      backupFileExtension = "hm-backup";
    };
  };
}
