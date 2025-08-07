{ lib, config, ... }:
{
  imports = [
    ./auto_upgrade
    ./system
    ./msmtp
    ./logging
  ];
}
