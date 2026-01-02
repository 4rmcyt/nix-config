_: {
  services = {
    ollama = {
      enable = true;
      acceleration = "cuda";
      loadModels = [
        "codellama:7b"
        "codellama:13b"
        "phi3:mini-4k"
      ];
    };
    open-webui.enable = true;
  };
}
