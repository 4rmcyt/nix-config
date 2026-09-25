{
  description = "4rmcyt's Nix configuration flake";

  inputs = {
    nix-auth.url = "github:numtide/nix-auth";
    flake-schemas.url = "github:DeterminateSystems/flake-schemas";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:numtide/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Plaintext identity/LAN topology values needed at eval time, kept out of this
    # public repo. See modules/options/private-example.nix.
    private.url = "git+ssh://git@github.com/4rmcyt/nix-config-private.git";

    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
      flake = false;
    };
    ucodenix.url = "github:e-tho/ucodenix";

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Not `hdr` (broken packaging: requests wlroots_0_19 but its C source needs 0.20).
    # Not `main` either: no working HDR output path (requires scenefx, which doesn't
    # support the vulkan renderer HDR needs) — `wl-only` drops that scenefx dependency.
    mango = {
      url = "github:mangowm/mango/wl-only";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # `cachix` branch always points at the latest CI-cached commit, avoiding an
    # uncached main commit that forces a local compile. No nixpkgs.follows here:
    # overriding it changes the derivation hash and causes a cache miss.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    # No nixpkgs input to follow — the flake only ships bare nixos/home-manager modules.
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zellij-nix = {
      url = "github:a-kenji/zellij-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-needsreboot.url = "git+https://codeberg.org/Mynacol/nixos-needsreboot.git";

    # Not following nixpkgs: upstream pins its own branch for a Go 1.26.4 security
    # fix (GO-2026-5037/5039) not yet in nixpkgs-unstable.
    headscale = {
      url = "github:juanfont/headscale";
    };

    ephraim-nur = {
      url = "github:EphraimSiegfried/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    ik-llama-cpp = {
      # Pinned rev so `nix flake update` can't bump it; bump by hand.
      url = "github:ikawrakow/ik_llama.cpp/1aaf7105be6e55a97fa4a9fd6f5bd362b08436dc";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Not following nixpkgs: pre-built and pushed to Cachix against arr-packages'
    # own nixpkgs rev — following ours would change the derivation hash and force
    # a local rebuild.
    arr-packages.url = "github:4rmcyt/arr-packages";
    jobshunting = {
      url = "github:4rmcyt/jobshunting";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        (inputs.import-tree ./parts)
      ];
    };
}
