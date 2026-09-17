{pkgs, ...}: {
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
      xkb-layout = "us";
      mode = "1920x1080";
      sb-size = 50000;
      mouse = true;
      palette = "base16-dark";
    };
  };
}
