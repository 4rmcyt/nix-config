{ pkgs, inputs, ... }:


{
  imports = [
    ../dots/nvim/default.nix
    ../dots/zsh/default.nix
  ];

  home.username = "zeev";
  home.homeDirectory = "/home/zeev";

  home.packages = with pkgs; [
    git
    nixfmt-rfc-style
    gnupg meslo-lgs-nf
  ];
  

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 14400;
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com";

      signing = {
        key = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E";
        signByDefault = true;
      };
    };

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.stateVersion = "25.05";
}