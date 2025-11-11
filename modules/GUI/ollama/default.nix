_: {
  users = {
    users.ollama = {
      isSystemUser = true;
      group = "ollama";
      extraGroups = [
        "users"
      ];
    };
    groups.ollama = {};
  };
  networking.firewall = {
    allowedTCPPorts = [
      11434 # Ollama API
      8080 # Open WebUI
    ];
  };

  services = {
    ollama = {
      enable = true;
      acceleration = "cuda";
      loadModels = [
        "codellama:7b"
        "codellama:13b"
        "llama3"
      ];
    };
    open-webui.enable = true;

    nixai = {
      enable = true;
      mcp = {
        enable = true;
        package = inputs.nixai.packages.${pkgs.stdenv.hostPlatform.system}.nixai;
        socketPath = "/run/nixai/mcp.sock";
        host = "localhost";
        port = 8080;
        documentationSources = [
          "https://wiki.nixos.org/wiki/NixOS_Wiki"
          "https://nix.dev/manual/nix"
          "https://nixos.org/manual/nixpkgs/stable/"
          "https://nix.dev/manual/nix/2.28/language/"
          "https://nix-community.github.io/home-manager/"
        ];
        aiProvider = "ollama"; # Options: "ollama", "gemini", "openai"
        aiModel = "codellama";
      };
    };
  };
}
