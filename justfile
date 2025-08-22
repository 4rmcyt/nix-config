# justfile

# Build the NixOS configuration for the homeserver
build-homeserver:
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel

# Build the Darwin configuration for the MacBook
build-macbook:
    nix build .#darwinConfigurations.macbook.system | cachix push macbookk

# Deploy to the NixOS homeserver
deploy-homeserver:
    ssh -t zeev@192.168.1.165 -- "cd ~/src/nixos-config && ssh-add ~/.ssh/zeev && git pull && nix flake update && sudo nixos-rebuild switch --flake .#homeserver | cachix push homeserver"

# Deploy to the Darwin MacBook
deploy-macbook:
    nix flake update && sudo darwin-rebuild switch --flake .#macbook && cachix push macbookk "$(nix-store -qR /run/current-system)"

# Format all code in the repository
fmt:
    nix fmt

# Update flake inputs
update:
    nix flake update

# Run garbage collection
gc:
    nix-collect-garbage -d

push-cache:
    cachix push macbookk "$(nix-store -qR /run/current-system)"
