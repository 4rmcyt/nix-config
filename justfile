# Deploy to gcp-relay
deploy-gcp:
    ./tools/scripts/caddy-plugins-update.sh --hashes-only gcp-relay
    nh os switch . -H gcp-relay --target-host zeev@gcp-relay
    nix build .#nixosConfigurations.gcp-relay.config.system.build.toplevel --no-link --print-out-paths | cachix push 4rmcyt-gcp

# Deploy to homeserver
deploy-homeserver:
    ./tools/scripts/caddy-plugins-update.sh --hashes-only homeserver
    nh os switch . -H homeserver --target-host zeev@homeserver

# Deploy to matebook
deploy-matebook:
    nh os switch . -H matebook --target-host zeev@matebook

# Rebuild the local machine (desktop is built here, never in CI)
deploy-local:
    nh os switch .

# Bump Caddy plugin tags (same major) and refresh their withPlugins hashes
caddy-update:
    ./tools/scripts/caddy-plugins-update.sh

# Update all flake inputs, then build the CI-covered hosts locally
update:
    nix flake update
    just caddy-update
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
