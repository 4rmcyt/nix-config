{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  nix.settings.trusted-users = [ "vk" ];

  # Comment out age secrets for now since it might not be configured for macOS
  # age.secrets.hashedUserPassword = {
  #   file = "${inputs.secrets}/hashedUserPassword.age";
  # };

  users.users.vk = {
    name = "vk";
    home = "/Users/vk";
    shell = pkgs.zsh;  # Add shell specification
  };

  programs.zsh.enable = true;
}