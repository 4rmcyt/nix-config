{
  pkgs,
  lib,
  ...
}: {
  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;

    settings = {
      # Experimental features (common to all hosts)
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Performance settings (can be overridden per host)
      cores = lib.mkDefault 0; # 0 = auto-detect
      max-jobs = lib.mkDefault "auto";
      download-buffer-size = lib.mkDefault 1073741824; # 1GB

      # Build settings
      fallback = lib.mkDefault true;
      show-trace = lib.mkDefault true;

      # Common substituters (hosts can add more)
      substituters = lib.mkDefault [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];

      # Common trusted public keys
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # Warn about dirty flakes
      warn-dirty = lib.mkDefault true;
    };
  };
}
