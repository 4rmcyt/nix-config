{ pkgs, ... }:
{
  fonts.packages = [
    pkgs.meslo-lgs-nf
    pkgs.nerd-fonts.symbols-only
  ];

  services.kmscon = {
    enable = true;
    config = {
      font-name = "MesloLGS Nerd Font";
      font-size = 16;
      hwaccel = true;
      gpus = "aux";
    };
  };
}
