# Deploy to homeserver
deploy-homeserver:
    ./deploy.sh homeserver

# Deploy to macbook  
deploy-macbook:
    ./deploy.sh macbook

# Update flake and test both systems
update:
    nix flake update
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel
    nix build .#darwinConfigurations.macbook.config.system.build.toplevel

# Push to both caches
push-caches:
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel | cachix push homeserver
    nix build .#darwinConfigurations.macbook.config.system.build.toplevel | cachix push macbookk

# Format all nix files
fmt:
    nixfmt **/*.nix

# Check for dead code
check:
    deadnix .

# Run all tests  
test:  
    nix flake check  
    just test-homeserver  
    just test-macbook  
  
# Test homeserver configuration  
test-homeserver:  
    nix build .#checks.x86_64-linux.homeserver-tests  
  
# Test macbook configuration    
test-macbook:  
    nix build .#checks.aarch64-darwin.macbook-tests    