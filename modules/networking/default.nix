{ lib, config, ... }:
{
  imports = [
    ./acme.nix
    ./base.nix
    ./cloudflared.nix
    ./nginx.nix
    ./tailscale.nix
  ];
}  
