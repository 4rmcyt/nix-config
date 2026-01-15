{pkgs, ...}: {
  services.kmscon = {
    enable = true;
    hwRender = true;
    fonts = [
      {
        name = "MesloLGS Nerd Font";
        package = pkgs.meslo-lgs-nf;
      }
    ];
    extraConfig = ''
      font-size=14
    '';
  };
}
