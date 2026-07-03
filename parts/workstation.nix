# Workstation-specific NixOS modules — desktop, laptop, homeserver.
# Not imported on headless appliances (router, gcp-relay).
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
in {
  modules.nixos.workstation = {
    imports = [
      inputs.nixos-facter-modules.nixosModules.facter
      inputs.ucodenix.nixosModules.default
    ];

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/${owner.username}/src/nix-config";
    };

    programs.gnupg.agent.enable = true;
  };
}
