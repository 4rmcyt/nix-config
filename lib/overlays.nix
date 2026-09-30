inputs: [
  inputs.mcp-servers-nix.overlays.default

  # mcp-servers-nix's @modelcontextprotocol/servers TS builds are broken from source
  # (tsc can't resolve @types/node); nixpkgs packages the same servers correctly.
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

  # every cuda-redist package's fixup crashes under __structuredAttrs (nixpkgs#323126/#422989:
  # multi-output arrays collapse to a single space-joined string); patch buildRedist itself so
  # all of cudaPackages (cuda_nvrtc, libcublas, ...) picks up the fix, not just one package
  (_final: prev: {
    cudaPackages = prev.cudaPackages.overrideScope (_cfinal: cprev: {
      buildRedist = args: (cprev.buildRedist args).overrideAttrs (_old: {__structuredAttrs = false;});
    });
  })
]
