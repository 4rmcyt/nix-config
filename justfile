# justfile

# Build the NixOS configuration for the homeserver
build-nixos:
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel

# Build the Darwin configuration for the MacBook
build-darwin:
    nix build .#darwinConfigurations.macbook.system

# Deploy to the NixOS homeserver
deploy-nixos:
    ssh -t zeev@192.168.1.165 -- "cd ~/src/nixos-config && ssh-add ~/.ssh/zeev && git pull && sudo nixos-rebuild switch --flake .#homeserver" |
    cachix push homeserver

# Deploy to the Darwin MacBook
deploy-darwin:
    nix build .#darwinConfigurations.macbook.system && sudo ./result/bin/darwin-rebuild switch --flake .#macbook && nix path-info -r ./result | cachix push macbookk

# Format all code in the repository
fmt:
    nix fmt

# Update flake inputs
update:
    nix flake update

# Run garbage collection
gc:
    nix-collect-garbage -d
