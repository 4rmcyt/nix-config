{ config, pkgs, ... }:
{
  imports = [
    ./zeev.nix
    # ./vk.nix  # Only import if needed for this host
  ];

  # Global user security settings
  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;

  # Security limits for all users
  security.pam.loginLimits = [
    {
      domain = "@users";
      type = "soft";
      item = "nofile";
      value = "4096";
    }
    {
      domain = "@users";
      type = "hard";
      item = "nofile";
      value = "8192";
    }
  ];
}
