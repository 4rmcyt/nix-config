{pkgs, ...}: {
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
      package = pkgs.ollama-cuda;
      loadModels = [
        "deepseek-coder"
      ];
    };
    # open-webui.enable = true;
  };
}
