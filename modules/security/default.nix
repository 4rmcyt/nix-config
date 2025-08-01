{ lib, config, ... }:
{
  imports = [
    ./authentik
    ./fail2ban
  ];

} 