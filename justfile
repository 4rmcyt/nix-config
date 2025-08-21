# justfile

# Build the NixOS configuration for the homeserver
build-nixos:
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel

# Build the Darwin configuration for the MacBook
build-darwin:
    nix build .#darwinConfigurations.macbook.system

# Deploy to the NixOS homeserver
deploy-nixos:
    ssh zeev@192.168.1.165 -- "cd ~/src/nixos-config && ssh-add ~/.ssh/id_zeev && git pull && sudo nixos-rebuild switch --flake .#homeserver"

# Deploy to the Darwin MacBook
deploy-darwin:
    sudo darwin-rebuild switch --flake .#macbook

# Format all code in the repository
fmt:
    nix fmt

# Update flake inputs
update:
    nix flake update

# Run garbage collection
gc:
    nix-collect-garbage -d