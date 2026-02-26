# Shared NixOS settings applied to all hosts via modules.nixos.base.
# Merges with the HM integration in home-manager-integration.nix.
{
  inputs,
  lib,
  ...
}: {
  modules.nixos.base = {config, ...}: {
    # Thread flake inputs into NixOS module args (replaces specialArgs)
    _module.args = {inherit inputs;};

    # Common nixpkgs config
    nixpkgs.config.allowUnfree = true;

    # Sops defaults
    sops.age.keyFile = lib.mkDefault "/root/.config/sops/age/keys.txt";

    # GitHub access token for nix daemon (rate limiting / private flake inputs)
    sops.secrets.nix_access_token = {
      sopsFile = ../secrets/common.yaml;
      key = "nix_access_token";
    };
    sops.templates."nix-daemon-env".content = "NIX_CONFIG=${config.sops.placeholder.nix_access_token}";
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile = config.sops.templates."nix-daemon-env".path;

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
        "https://nix-gaming.cachix.org?priority=3"
        "https://devenv.cachix.org?priority=4"
        "https://nixpkgs-unfree.cachix.org?priority=5"
      ];
      extra-trusted-public-keys = [
        "4rmcyt.cachix.org-1:yHVDqXs6TDmfSOuPbl4gcfomDK9gzTmK8FabfHLi+d8="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nqlt4="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "llama-cpp.cachix.org-1:H75X+w83wUKTIPSO1KWy9ADUrzThyGs8P5tmAbkWhQc="
      ];
    };
  };
}
