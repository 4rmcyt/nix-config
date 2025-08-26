{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = [
    pkgs.sops
    pkgs.age
    pkgs.git
    pkgs.just
    pkgs.nixfmt-rfc-style
    pkgs.deadnix
    pkgs.shfmt
    pkgs.cachix
  ];
  
  shellHook = ''
    echo "Available caches: homeserver, macbookk"
    echo "Deploy with: ./deploy.sh [homeserver|macbook]"
    echo ""
    echo "Note: Use '--accept-flake-config' flag to trust flake cache settings"
    echo "Example: nix build --accept-flake-config .#nixosConfigurations.homeserver.config.system.build.toplevel"
    echo ""
    
    # Auto-configure cachix if token is available
    if [ -n "''${CACHIX_AUTH_TOKEN:-}" ]; then
      echo "CACHIX_AUTH_TOKEN found, configuring cachix..."
      cachix authtoken "$CACHIX_AUTH_TOKEN" 2>/dev/null || true
    fi
    
    # Set up aliases for common commands
    alias nix-build-accept="nix build --accept-flake-config"
    alias nix-develop-accept="nix develop --accept-flake-config"
  '';
}