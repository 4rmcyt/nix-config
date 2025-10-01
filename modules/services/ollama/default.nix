_: {
  services.ollama.enable = true;
  services.ollama.acceleration = "cuda";
  services.ollama.loadModels = [
    "codellama:7b"
    "codellama:13b"
    "phi3:mini-4k"
  ];
  services.open-webui.enable = true;

  nix.settings = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
}
