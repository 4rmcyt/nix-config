{ pkgs, ... }:

{
  # This test runs in a VM, suitable for NixOS
  homeserverTest = import ./homeserver.nix { inherit pkgs; };

  # This creates a script package that can be run on the live system
  macbookTestScript = import ./macbook.nix { inherit pkgs; };
}