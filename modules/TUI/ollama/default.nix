{ pkgs, config, ... }:
{
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

  # Create environment file for Open WebUI secrets
  sops.templates."open-webui-env" = {
    content = ''
      OPENAI_API_KEYS=${config.sops.placeholder.gemini_api_key}
    '';
    owner = "open-webui";
    group = "open-webui";
    mode = "0400";
  };

  services = {
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      loadModels = [
        "deepseek-coder-v2"
      ];
    };
    open-webui = {
      enable = true;
      environment = {
        # Gemini API via OpenAI-compatible endpoint
        OPENAI_API_BASE_URLS = "https://generativelanguage.googleapis.com/v1beta/openai";
        ENABLE_OPENAI_API = "True";
      };
      environmentFile = config.sops.templates."open-webui-env".path;
    };
  };
}
