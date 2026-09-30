inputs: [
  inputs.mcp-servers-nix.overlays.default

  # mcp-servers-nix's TS builds are broken from source (tsc can't resolve @types/node); use nixpkgs' instead
  (_final: prev: {
    inherit
      (import inputs.nixpkgs {inherit (prev) system;})
      mcp-server-memory
      mcp-server-filesystem
      mcp-server-sequential-thinking
      ;
  })

  inputs.nur.overlays.default
  inputs.nix-vscode-extensions.overlays.default
  inputs.noctalia.overlays.default

  # cuda-redist fixup crashes under __structuredAttrs (nixpkgs#323126/#422989); patch buildRedist so it covers all of cudaPackages
  (_final: prev: {
    cudaPackages = prev.cudaPackages.overrideScope (_cfinal: cprev: {
      buildRedist = args: (cprev.buildRedist args).overrideAttrs (_old: {__structuredAttrs = false;});
    });
  })
]
