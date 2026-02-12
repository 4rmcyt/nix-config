Review code changes:

1. Run `git diff` (or `git diff --staged`) to see changes
2. Read full files for context around each change
3. Check against:
   - NixOS/Nix idioms and best practices
   - Repository conventions (module structure, naming, formatting)
   - Security (no plaintext secrets, proper sops usage)
   - Correctness (valid Nix syntax, correct option types)
4. Use mcp-nixos to verify any NixOS options referenced
5. Report findings grouped by severity (critical/warning/info)
6. Suggest specific fixes with code snippets
