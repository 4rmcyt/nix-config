{ config, pkgs, lib, inputs, ... }:
{
  home.username = "vk";
  home.homeDirectory = "/Users/vk";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "ls -la";
      la = "ls -la";
      l = "ls -l";
      ".." = "cd ..";
      "..." = "cd ../..";
      grep = "grep --color=auto";
      rebuild = "darwin-rebuild switch --flake .";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "kubectl" ];
      theme = "robbyrussell";
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "vk";
    userEmail = "your-email@example.com";  # Replace with your email
    
    extraConfig = {
      init.defaultBranch = "main";
      push.default = "simple";
      pull.rebase = true;
    };
  };

  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # FZF fuzzy finder
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # SSH configuration
  programs.ssh = {
    enable = true;
    
    matchBlocks = {
      "homeserver" = {
        hostname = "your-homeserver-ip";  # Replace with actual IP
        user = "zeev";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # macOS-specific configurations
  targets.darwin.defaults = {
    # Dock preferences
    "com.apple.dock" = {
      autohide = true;
      orientation = "bottom";
      tilesize = 48;
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "iterm2";
  };

  # Home packages (user-specific)
  home.packages = with pkgs; [
    # Development tools
    nodejs
    python3
    go
    rustc
    cargo
    
    # CLI utilities
    htop
    tree
    wget
    curl
    jq
    yq
    
    # macOS-specific tools
    mas
    m-cli
  ];
}