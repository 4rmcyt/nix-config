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

# Update flake and test all systems
update:
    nix flake update
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel
    nix build .#darwinConfigurations.macbook.config.system.build.toplevel

# Push the currently running system to its own host cache
push-caches:
    cachix push 4rmcyt-$(hostname) /run/current-system

# Format all nix files
fmt:
    nix fmt

# Check for dead code
check:
    nix flake check

# Render nix-topology diagrams into docs/ (git-ignored — resolve real IPs)
topology:
    nix build .#topology.x86_64-linux.config.output -o result-topology
    install -m 644 result-topology/main.svg docs/topology.svg
    install -m 644 result-topology/network.svg docs/topology-network.svg
    rm -f result-topology

# Run all tests
test:
    nix flake check

# Test homeserver configuration


build-iso $host:
    just copy {{ host }}; ssh {{ host }} "nix-shell -p nixos-generators.out --run 'nixos-generate -c /etc/nixos/machines/installer/default.nix -f install-iso -I nixpkgs=channel:unstable'"

dry-run $host:
    nixos-rebuild-ng dry-activate --flake .#{{ host }} --target-host {{ host }} --build-host {{ host }} --fast --use-remote-sudo

deploy $host: (copy host)
    nixos-rebuild-ng switch --flake .#{{ host }} --target-host {{ host }} --build-host {{ host }} --fast --use-remote-sudo

check-clean:
    if [ -n "$(git status --porcelain)" ]; then echo -e "\e[31merror\e[0m: git tree is dirty. Refusing to copy configuration." >&2; exit 1; fi

copy $host: check-clean
    rsync -ax --delete --rsync-path="sudo rsync" ./ {{ host }}:/etc/nixos/

deploy-desktop:
    ./deploy.sh desktop

# ...existing code...

# Test desktop configuration
test-desktop:
    nix build .#nixosConfigurations.desktop.config.system.build.toplevel
