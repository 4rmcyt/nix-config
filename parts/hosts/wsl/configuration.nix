# WSL host definition via Dendritic configurations.nixos option.
{config, ...}: let
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.wsl.module = {...}: {
    imports = [
      nixosBase
      ../../../hosts/nixos/wsl
    ];
  };
}
