# Deploy to gcp-relay
deploy-gcp:
    nh os switch --hostname gcp-relay --target-host zeev@gcp-relay --elevation-strategy passwordless ~/src/nix-config

# Deploy to homeserver
deploy-homeserver:
    ./deploy.sh homeserver

# Deploy to WSL
deploy-wsl:
    ./deploy.sh wsl

# Update flake and test all systems
update:
    nix flake update
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel
    nix build .#darwinConfigurations.macbook.config.system.build.toplevel
    nix build .#nixosConfigurations.wsl.config.system.build.toplevel

# Push to all caches
push-caches:
    nix build .#nixosConfigurations.homeserver.config.system.build.toplevel | cachix push homeserver
    nix build .#darwinConfigurations.macbook.config.system.build.toplevel | cachix push macbookk
    nix build .#nixosConfigurations.wsl.config.system.build.toplevel | cachix push homeserver

# Format all nix files
fmt:
    nixfmt **/*.nix

# Check for dead code
check:
    nix flake check

# Run all tests
test:
    nix flake check
    just test-homeserver
    just test-wsl

# Test homeserver configuration
test-homeserver:
    nix build .#checks.x86_64-linux.homeserver-tests

# Test WSL configuration
test-wsl:
    nix build .#nixosConfigurations.wsl.config.system.build.toplevel

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
