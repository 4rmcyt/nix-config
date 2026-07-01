{pkgs, ...}: {
  imports = [
    ./plugins.nix
    ./lsp.nix
    ./keymaps.nix
  ];

  programs.nixvim = {
    nixpkgs.source = pkgs.path;
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    colorschemes.kanagawa = {
      enable = true;
      settings.theme = "wave";
    };

    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      wrap = false;
      termguicolors = true;
      scrolloff = 8;
      signcolumn = "yes";
      updatetime = 50;
      cursorline = true;
      clipboard = "unnamedplus";
      mouse = "a";
      undofile = true;
      ignorecase = true;
      smartcase = true;
      splitbelow = true;
      splitright = true;
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };
  };
}
