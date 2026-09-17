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
      # Standard Gruvbox dark 16-color terminal palette.
      palette = "custom";
      palette-black = "40,40,40";
      palette-red = "204,36,29";
      palette-green = "152,151,26";
      palette-yellow = "215,153,33";
      palette-blue = "69,133,136";
      palette-magenta = "177,98,134";
      palette-cyan = "104,157,106";
      palette-light-grey = "168,153,132";
      palette-dark-grey = "146,131,116";
      palette-light-red = "251,73,52";
      palette-light-green = "184,187,38";
      palette-light-yellow = "250,189,47";
      palette-light-blue = "131,165,152";
      palette-light-magenta = "211,134,155";
      palette-light-cyan = "142,192,124";
      palette-white = "235,219,178";
      palette-foreground = "235,219,178";
      palette-background = "40,40,40";
    };
  };
}
