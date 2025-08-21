# File: nixos-config/modules/users/vk/default.nix
{ config, ... }:
{
  sops.secrets.vk_password = {
    sopsFile = ../../../secrets/common.yaml;
    key = "vk_password";
  };


  users.users = {
    vk = {
      isNormalUser = true;
      description = "vk";
      hashedPasswordFile = config.sops.secrets.vk_password.path;
    };
  };
}