{
  config,
  pkgs,
  ...
}: let
  pythonWithLitellm = pkgs.python3.withPackages (ps: [
    ps.litellm
  ]);

  litellmConfig = pkgs.writeText "litellm-config.yaml" ''
    model_list:
      # Gemini models via API
      - model_name: gemini-flash
        litellm_params:
          model: gemini/gemini-3-flash
          api_key: os.environ/GEMINI_API_KEY

      - model_name: gemini-pro
        litellm_params:
          model: gemini/gemini-3-pro
          api_key: os.environ/GEMINI_API_KEY

      # Local Ollama models
      - model_name: qwen-coder
        litellm_params:
          model: ollama/qwen2.5-coder:7b
          api_base: http://localhost:11434
  '';

  # Script to load secrets and start litellm
  startScript = pkgs.writeShellScript "litellm-start" ''
    export GEMINI_API_KEY=$(cat ${config.sops.secrets.gemini_api_key.path})
    exec ${pythonWithLitellm}/bin/litellm --config ${litellmConfig} --port 4000
  '';
in {
  sops.secrets.gemini_api_key = {
    sopsFile = ../../../secrets/common.yaml;
    owner = "litellm";
    group = "litellm";
  };

  users = {
    users.litellm = {
      isSystemUser = true;
      group = "litellm";
    };
    groups.litellm = {};
  };

  networking.firewall.allowedTCPPorts = [
    4000 # LiteLLM proxy
  ];

  systemd.services.litellm = {
    description = "LiteLLM Proxy Server";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "ollama.service"];

    serviceConfig = {
      Type = "simple";
      User = "litellm";
      Group = "litellm";
      ExecStart = startScript;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
