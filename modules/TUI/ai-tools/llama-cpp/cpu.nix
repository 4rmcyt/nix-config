{
  pkgs,
  lib,
  ...
}: let
  qwen-model = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf";
    hash = "sha256-YmtKZni4ZEIkDjPfgZ4AEy07p93f4c3E+7GOCpYVxi0=";
  };
in {
  home.packages = [pkgs.llama-cpp];

  systemd.user.services.llama-cpp = {
    Unit = {
      Description = "llama.cpp inference server (CPU)";
      After = ["default.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.llama-cpp}/bin/llama-server"
        "--model ${qwen-model}"
        "--alias qwen-local"
        "--host 127.0.0.1"
        "--port 8080"
        "--threads 4"
        "--ctx-size 8192"
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
      ];
      MemoryMax = "4G";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
