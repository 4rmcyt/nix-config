{
  config,
  pkgs,
  ...
}: let
  routellmPkg = pkgs.python312Packages.routellm;
  threshold = "0.4";
in {
  environment.systemPackages = [
    routellmPkg
    pkgs.python312Packages.litellm
  ];

  # Global RouteLLM configuration
  environment.etc."routellm/config.yaml".text = ''
    model_list:
      - model_name: strong
        litellm_params:
          model: gemini/gemini-3-pro
          api_key: "os.environ/GOOGLE_API_KEY"
      - model_name: weak
        litellm_params:
          model: ollama/qwen2.5-coder:14b
          api_base: http://localhost:11434
  '';

  systemd.services.routellm = {
    description = "RouteLLM System Proxy (Local + Gemini)";
    after = ["network.target" "ollama.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      User = "root";
      Group = "root";

      ExecStart = ''
        ${routellmPkg}/bin/python -m routellm.server \
          --router mf \
          --strong-model strong \
          --weak-model weak \
          --threshold ${threshold} \
          --port 6000
      '';

      EnvironmentFile = config.sops.secrets.gemini_api_key.path;

      Restart = "on-failure";
      RestartSec = "10s";
      MemoryMax = "512M";
    };
  };
}
