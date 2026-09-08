# nixpkgs overlays for the Home Manager pkgs instance (parts/home-manager-base.nix).
# The system nixpkgs uses no overlays.
inputs: [
  inputs.mcp-servers-nix.overlays.default

  # mcp-servers-nix's @modelcontextprotocol/servers TS builds are broken from
  # source (tsc can't resolve @types/node → TS2591). nixpkgs packages the same
  # servers correctly (postPatch sets compilerOptions.types). Keep the
  # mcp-servers-nix overlay only for tavily-mcp (not in nixpkgs).
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
]
