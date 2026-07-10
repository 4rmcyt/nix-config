# Workstation-specific NixOS modules — desktop, laptop, homeserver.
# Not imported on headless appliances (router, gcp-relay).
{inputs, ...}: {
  modules.nixos.workstation = {
    imports = [
      inputs.nixos-facter-modules.nixosModules.facter
      inputs.ucodenix.nixosModules.default
    ];

    programs.gnupg.agent.enable = true;
  };
}
