_: {
  users = {
    users.ollama = {
      isSystemUser = true;
      group = "ollama";
      extraGroups = [
        "users"
      ];
    };
    groups.ollama = { };
  };
  networking.firewall = {
    allowedTCPPorts = [
      11434 # Ollama API
      8080 # Open WebUI
    ];
  };

  services.ollama.enable = true;
  services.ollama.acceleration = "cuda";
  services.ollama.loadModels = [
    "codellama:7b"
    "codellama:13b"
  ];
  services.open-webui.enable = true;
}
