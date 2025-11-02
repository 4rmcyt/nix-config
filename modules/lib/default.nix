{
  config,
  lib,
  pkgs,
  ...
}: {
  # Re-export all helper functions from individual lib files
  imports = [
    ./nginx.nix
    ./sops.nix
    ./users.nix
    ./tmpfiles.nix
  ];
}
