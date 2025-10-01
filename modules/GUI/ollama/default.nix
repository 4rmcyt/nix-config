_: {
  services.ollama.enable = true;
  services.ollama.acceleration = "cuda";
  services.ollama.loadModels = [
    "codellama:7b"
    "codellama:13b"
  ];
  services.open-webui.enable = true;
}
