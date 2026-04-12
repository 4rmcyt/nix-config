# Shared NixOS settings applied to all hosts via modules.nixos.base.
# Merges with the HM integration in home-manager-integration.nix.
{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config.meta) stateVersion;
in
{
  modules.nixos.base =
    {
      config,
      pkgs,
      ...
    }:
    {
      system.stateVersion = lib.mkDefault stateVersion;
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      _module.args = { inherit inputs; };

      nixpkgs.config.allowUnfree = true;

      sops.age.keyFile = lib.mkDefault "/root/.config/sops/age/keys.txt";

      sops.secrets.nix_access_token = {
        sopsFile = ../secrets/common.yaml;
        key = "nix_access_token";
        owner = "root";
      };
      sops.templates."nix-daemon-access-tokens.env" = {
        # NIX_CONFIG env var is read by nix-daemon to extend its config
        content = "NIX_CONFIG=${config.sops.placeholder.nix_access_token}\n";
        path = "/run/nix-daemon-access-tokens.env";
        restartUnits = [ "nix-daemon.service" ];
      };
      systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
        "/run/nix-daemon-access-tokens.env";

      # Lix as the nix implementation
      nix.package = lib.mkDefault pkgs.lixPackageSets.latest.lix;
      nix.channel.enable = false;
      nix.registry.nixpkgs.flake = inputs.nixpkgs;

      # Common nix daemon settings (host-specific: cores, max-jobs, trusted-users, extra-system-features)
      nix.settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "auto-allocate-uids"
        ];
        auto-optimise-store = true;
        warn-dirty = false;
        keep-going = true;
        max-substitution-jobs = 16;
        http-connections = 25;
        stalled-download-timeout = 60;
        keep-outputs = true;
        keep-derivations = true;
        connect-timeout = 5;
        min-free = 5368709120; # 5GB
        max-free = 10737418240; # 10GB
        narinfo-cache-negative-ttl = 0;
        builders-use-substitutes = true;
        require-sigs = true;
        eval-cache = true;
      };

      # Binary caches
      nix.settings = {
        extra-substituters = [
          "https://4rmcyt.cachix.org?priority=0"
          "https://nix-community.cachix.org?priority=1"
          "https://cache.nixos.org?priority=1"
          "https://cache.lix.systems?priority=1"
          "https://cache.flox.dev?priority=1"
          "https://cache.nixos-cuda.org?priority=1"
          "https://cuda-maintainers.cachix.org?priority=1"
          "https://llama-cpp.cachix.org?priority=1"
          "https://noctalia.cachix.org?priority=2"
          "https://devenv.cachix.org?priority=3"
          "https://nixpkgs-unfree.cachix.org?priority=5"
        ];
        extra-trusted-public-keys = [
          "4rmcyt.cachix.org-1:yHVDqXs6TDmfSOuPbl4gcfomDK9gzTmK8FabfHLi+d8="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nqlt4="
          "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          "llama-cpp.cachix.org-1:H75X+w83wUKTIPSO1KWy9ADUrzThyGs8P5tmAbkWhQc="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };
    };
}
