{ pkgs, inputs, ... }: {
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.packages = with pkgs; [
    git nixfmt-rfc-style
  ];
  imports = [
    inputs.nix4nvchad.homeManagerModules.default
  ];


  programs = {
    # 0. General Home Manager Configuration
    home-manager = {
      enable = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      homeDirectory = "/home/zeev";
      zsh = {
        enable = true;
        enableCompletion = true;
        initContent = "setopt autocd";

      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch --flake .#homeserver";
      };

        plugins = [
          { name = "zsh-autosuggestions"; src = pkgs.zsh-autosuggestions; }
          { name = "zsh-completions"; src = pkgs.zsh-completions; }
          { name = "zsh-history-substring-search"; src = pkgs.zsh-history-substring-search; }
          { name = "zsh-syntax-highlighting"; src = pkgs.zsh-syntax-highlighting; }
          { name = "you-should-use"; src = pkgs.zsh-you-should-use; }
          {
            name = "do-you-even-nix";
  	        file = "do-you-even-nix.zsh-theme";
  	        src = pkgs.fetchFromGitHub {
              owner = "miche1e";
              repo = "do-you-even-nix";
              rev = "v1.0.1";
              sha256 = "n9QYjpXlGdLx6agwp14rwcc6Jr5+0E/2h/oMuFsveHA=";
            };
          }
        ];

          oh-my-zsh = {
            enable = true;
            plugins = [ "git" "sudo" ];
            theme = "do-you-even-nix";
          };
      };
    };
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
    nvchad.enable = true;
    xdg.configFile."nvim/lua/custom/chadrc.lua".text = ''
      -- This is my custom chadrc
      ---@type ChadrcConfig
      local M = {}
      M.ui = {
      theme = 'onedark',
      }
    return M
    '';
    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com";
      extraConfig = {
        "Host github.com" = {
          HostName = "github.com";
          IdentityFile = "~/.ssh/zeev";
          IdentitiesOnly = "yes";
        };
      };
    };
  };
  
  home.stateVersion = "25.05";
}

