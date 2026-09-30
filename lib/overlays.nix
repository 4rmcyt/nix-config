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

  # intel-compute-runtime-legacy1 (frozen at 24.35.30872.41, no gcc16 patch upstream) fails
  # under gcc-16's stricter -Werror=sfinae-incomplete; downgrade it to a warning
  (_final: prev: {
    intel-compute-runtime-legacy1 = prev.intel-compute-runtime-legacy1.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = toString (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error=sfinae-incomplete";
    });
  })
]
