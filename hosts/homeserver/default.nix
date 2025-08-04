{ ... }:
{
  imports = [
    # Hardware and user definitions remain
    ./hardware-configuration.nix
    ../../modules/users/zeev.nix

    # Modularized configuration components
    ../../modules/base/server      # Core system settings
    ../../modules/security/sops 
    ../../modules/security        
    ../../modules/networking
    ../../modules/backup
    ../../modules/monitoring
    ../../modules/containers
    ../../modules/database

    # Services are now imported individually
    ../../modules/services/ssh
  ];
}