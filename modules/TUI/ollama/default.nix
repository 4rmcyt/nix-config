{pkgs, ...}: {
  users = {
    users.ollama = {
      isSystemUser = true;
      group = "ollama";
      extraGroups = ["users"];
    };
    groups.ollama = {};
  };

  networking.firewall.allowedTCPPorts = [
    11434 # Ollama API
  ];

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    loadModels = [
      "qwen2.5-coder:14b"
      "qwen2.5-coder:3b"
      "deepseek-r1:14b"
    ];
  };
}
