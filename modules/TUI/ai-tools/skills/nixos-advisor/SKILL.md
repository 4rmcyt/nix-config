# NixOS Advisor

Help users find and configure NixOS options and packages using mcp-nixos.

## Instructions

1. When asked about configuring a NixOS service or option:
   - Use mcp-nixos to search for relevant options
   - Present option name, type, default, and description
   - Show example configuration snippet following nix-config patterns

2. When asked about packages:
   - Search nixpkgs via mcp-nixos
   - Show package name, version, description
   - Suggest where to add it: `home.packages` (user) vs `environment.systemPackages` (system)

3. For Home Manager questions:
   - Search Home Manager options via mcp-nixos
   - Show option path and usage in the nix-config module structure

4. Always verify options exist before suggesting them. Check channel compatibility (unstable vs stable).
