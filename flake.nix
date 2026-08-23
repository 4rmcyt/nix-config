{
  description = "4rmcyt's Nix configuration flake";

  inputs = {
    # Core
    determinate.url = "github:DeterminateSystems/determinate";
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

    # NixOS infrastructure
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

    # Secrets
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware & system
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
      flake = false;
    };
    ucodenix.url = "github:e-tho/ucodenix";

    # Dev tools
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
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # IDE & editors
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Desktop & GUI
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # NOT the `hdr` branch: tried it (2026-08-23) — it's broken, not just
    # stale. Its own nix/default.nix requests wlroots_0_19 while its C
    # source (meson.build) has already moved to wlroots-0.20, so it fails
    # at meson's configure step ("Dependency wlroots-0.20 not found") —
    # the branch's Nix packaging was never updated to match its own C code.
    # mainline mango has no working HDR output path either way (bundles
    # scenefx, no vulkan renderer) — HDR isn't reachable via mango right
    # now without fixing that branch upstream first.
    mango = {
      url = "github:mangowm/mango";
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
    # cachix branch, not main — always points at the latest commit noctalia's
    # own CI has finished caching to noctalia.cachix.org, so this never pulls
    # an uncached main commit that would force a local compile.
    #
    # No `inputs.nixpkgs.follows` here (unlike most other inputs): overriding
    # noctalia's nixpkgs changes its derivation hash and causes a cache miss
    # against noctalia.cachix.org, forcing a full local meson/ninja C++
    # build instead of a substituted binary. Costs one extra nixpkgs
    # evaluation in the closure; buys a guaranteed cache hit.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    # No nixpkgs input to follow — the flake only ships bare nixos/home-manager modules.
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # pam-shim = {
    #   url = "github:Cu3PO42/pam_shim/next";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    stylix.url = "github:danth/stylix";

    # Shell & TUI
    zellij-nix = {
      url = "github:a-kenji/zellij-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-needsreboot.url = "git+https://codeberg.org/Mynacol/nixos-needsreboot.git";

    # Headscale control server — not following nixpkgs: upstream pins its own
    # nixpkgs branch for a Go 1.26.4 security fix (GO-2026-5037/5039) that
    # hasn't reached nixpkgs-unstable yet.
    headscale = {
      url = "github:juanfont/headscale";
    };

    # Services & infrastructure
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
    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Sonarr/Radarr/Prowlarr/Bazarr/Jellyfin built from upstream release tags,
    # not nixpkgs' pin. Deliberately NOT following nixpkgs: these packages are
    # pre-built and pushed to Cachix against arr-packages' own nixpkgs rev —
    # following ours would change the derivation hash and force a local rebuild.
    arr-packages.url = "github:4rmcyt/arr-packages";
    # job-kombayn: script tree (run.py, kombayn/, profiles/). Now a real flake
    # (formatter only, via treefmt-nix) - follow our nixpkgs so it doesn't
    # pull its own copy just to build the treefmt wrapper.
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
