# Deploy to gcp-relay
deploy-gcp:
    nixos-rebuild switch --flake .#gcp-relay --target-host zeev@gcp-relay --build-host localhost --elevate=sudo --ask-elevate-password
    nix build .#nixosConfigurations.gcp-relay.config.system.build.toplevel --no-link --print-out-paths | cachix push 4rmcyt-gcp
    sudo nh clean all

# Deploy to homeserver
deploy-homeserver:
    nixos-rebuild switch --flake .#homeserver --target-host zeev@homeserver --build-host localhost --elevate=sudo --ask-elevate-password

# Deploy to matebook
deploy-matebook:
    nixos-rebuild switch --flake .#matebook --target-host zeev@matebook --build-host localhost --elevate=sudo --ask-elevate-password

# Rebuild the local machine (desktop is built here, never in CI)
deploy-local:
    sudo nixos-rebuild switch --flake ".#$(hostname)"

# Update all flake inputs, then build the CI-covered hosts locally
update:
    nix flake update
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel
    nix build .#nixosConfigurations.matebook.config.system.build.toplevel
    nix build .#nixosConfigurations.gcp-relay.config.system.build.toplevel

# Push the currently running system to its own host cache
push-caches:
    cachix push 4rmcyt-$(hostname) /run/current-system

# Format the tree
fmt:
    nix fmt

# Validate flake outputs
check:
    nix flake check

# Render nix-topology diagrams into docs/ (committed; IP-free labels)
topology:
    nix build .#topology.x86_64-linux.config.output -o result-topology
    install -m 644 result-topology/main.svg docs/topology.svg
    install -m 644 result-topology/network.svg docs/topology-network.svg
    rm -f result-topology
