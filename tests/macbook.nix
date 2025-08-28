{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "macbook-post-rebuild-tests";
  runtimeInputs = with pkgs; [
    coreutils
    gnugrep
    procps
  ]; # Dependencies for the script
  text = ''
    #!/usr/bin/env bash

    # Color codes for output
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'

    # Function to run a test and print the result
    run_test() {
        local test_name="$1"
        local command_to_run="$2"
        echo -n "🧪 Running test: '$test_name'... "
        if eval "$command_to_run"; then
            echo -e "''${GREEN}PASSED''${NC}"
        else
            echo -e "''${RED}FAILED''${NC}"
        fi
    }

    echo "--- 🏡 Home Manager Integrity Checks ---"
    run_test "Git config is a symlink managed by Home Manager" "[ -L ~/.gitconfig ] && readlink ~/.gitconfig | grep -q '/nix/store'"
    run_test "Zsh config is a symlink managed by Home Manager" "[ -L ~/.zshrc ] && readlink ~/.zshrc | grep -q '/nix/store'"
    run_test "Helix config is a symlink" "[ -L ~/.config/helix/config.toml ] && readlink ~/.config/helix/config.toml | grep -q '/nix/store'"

    echo -e "\n--- 📦 Package and Application Tests ---"
    run_test "Homebrew cask 'Firefox' is installed" "brew list --cask | grep -q 'firefox'"
    run_test "Homebrew formula 'ripgrep' is installed" "brew list --formula | grep -q 'ripgrep'"
    run_test "Application 'Docker' exists in /Applications" "[ -d '/Applications/Docker.app' ]"
    run_test "GitHub CLI is authenticated" "gh auth status &> /dev/null"

    echo -e "\n--- 🔒 Security and Agent Tests ---"
    run_test "GPG Agent is running" "pgrep -x 'gpg-agent' &> /dev/null"
  '';
}
