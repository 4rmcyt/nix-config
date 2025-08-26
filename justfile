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
    nix flake check

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


build-iso $host:
	just copy {{ host }}; ssh {{ host }} "nix-shell -p nixos-generators.out --run 'nixos-generate -c /etc/nixos/machines/installer/default.nix -f install-iso -I nixpkgs=channel:unstable'"
  

dry-run $host:
	nixos-rebuild-ng dry-activate --flake .#{{host}} --target-host {{host}} --build-host {{host}} --fast --use-remote-sudo

deploy $host: (copy host)
	nixos-rebuild-ng switch --flake .#{{host}} --target-host {{host}} --build-host {{host}} --fast --use-remote-sudo

check-clean:
	if [ -n "$(git status --porcelain)" ]; then echo -e "\e[31merror\e[0m: git tree is dirty. Refusing to copy configuration." >&2; exit 1; fi

copy $host: check-clean
	rsync -ax --delete --rsync-path="sudo rsync" ./ {{host}}:/etc/nixos/    