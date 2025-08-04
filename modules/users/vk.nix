{
  config,
  inputs,
  pkgs,
  ...
}:
{
  nix.settings.trusted-users = [ "vk" ];

  age.secrets.hashedUserPassword = {
    file = "${inputs.secrets}/hashedUserPassword.age";
  };

  users.users.vk = {
    name = "vk";
    home = "/Users/vk";
  };

  programs.zsh.enable = true;

}