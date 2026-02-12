# NixOS Command Not Found

When a command is not found:

1. Use mcp-nixos to search for packages providing the command
2. If found, suggest running with: `nix shell nixpkgs#<package> -c <command> [args]`
3. If the user wants it permanently, suggest adding to:
   - User tool: `home.packages` in the relevant home module
   - System tool: `environment.systemPackages` in the host config
4. If multiple packages provide the command, list them and ask which to use
5. If no package found, search with tavily for alternatives
