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
]
