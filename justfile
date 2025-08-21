# justfile

# Build the NixOS configuration for homeserver
build:
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel

# Deploy to homeserver
deploy:
    nixos-rebuild switch --flake .#homeserver

# Format all code in the repository
fmt:
    nix fmt

# Update flake inputs
update:
    nix flake update

# Run garbage collection
gc:
    nix-collect-garbage -d