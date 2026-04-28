{pkgs, ...}: {
  services.kmscon = {
    enable = true;
    hwRender = true;
    fonts = [
      {
        name = "MesloLGS Nerd Font";
        package = pkgs.meslo-lgs-nf;
      }
      {
        name = "Symbols Nerd Font Mono";
        package = pkgs.nerd-fonts.symbols-only;
      }
    ];
    extraConfig = ''
      font-size=16
      hwaccel
      gpus=aux
    '';
  };
}
