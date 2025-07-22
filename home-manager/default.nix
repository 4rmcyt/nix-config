{ pkgs, inputs, ... }:

{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";

  home.packages = with pkgs; [
    git
    nixfmt-rfc-style
    gnupg zsh-powerlevel10k meslo-lgs-nf
  ];
  
  imports = [
    ./dots/nvim/default.nix
  ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
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

    imports = [
      ../../dots/zsh/default.nix
      ../../dots/nvim/default.nix
    ];
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.stateVersion = "25.05";
}