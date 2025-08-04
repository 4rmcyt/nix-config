{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  # Replace these with the actual contents from your ~/.ssh/*.pub files
  user-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAokdbrMinZjhDnVLnrXOjNn9SvzsPdlP6P3T9hAtGG8 vk@Volodymyr-Kondratenko-Mac.local";
  user-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc3zaVdT+TBJdjBWbN2fwSricHc7yJFGPxB9PB2sR4mkCmv6FPBd8vGZ1pYLJWEqgPU0C76IWAiSpwRrYu4Da0JKyEITh69sT+ndufTsrXJwPPxFKsUnmm2XQE0O2M2dM3wx+sMnBxWc1AMlfkWDnpP2N1Rl33ridumzEAGvJGqrn/ScpHGSgEkpZwVAnO5U8S9EjuO0h+nUJUSfLJVcl/cLeqHuF5zE8mSxsrj1FjiymZSquOEVAwNOhbCLuFVsYSEb8qujFsD7M9Umd0qvPQwCY9zN/Hb37TrNebhJ32kjIOlrWO3fnreMetIVRtTC1/cvKnGV16S32/YGiIUb2zLTfxKp2bn2qvXgLwocKf/M56fobQ6LOt60dUG1y3QwRLI1uAQggzp2N3/shQRb89nCQ/Zq67h941U2Z/RnNx7Hzl6n9DHkiKmkvXQuld0DWgh6wwG775gR2wBZHgpqtLqoRhwFVrvwIL9UkrLL4PE9A5iBEmypWsCWUomi5St+k= vk@Volodymyr-Kondratenko-Mac.local";
 
  user-keys = [
    user-ed25519
    user-rsa
  ];
in
{
  users.users.vk = {
    name = "vk";
    home = "/Users/vk";
    openssh.authorizedKeys.keys = user-keys;
  };

  programs.zsh.enable = true;
  
  # Add trusted users for nix
  nix.settings.trusted-users = [ "vk" "@admin" ];
}