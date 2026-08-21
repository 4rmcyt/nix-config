{
  pkgs,
  lib,
  ...
}: let
  qwen-story-model = pkgs.fetchurl {
    url = "https://huggingface.co/bartowski/Qwen2.5-32B-Instruct-GGUF/resolve/main/Qwen2.5-32B-Instruct-Q4_K_M.gguf";
    hash = "sha256-Ll9trqGA28WfZaQGQelNOXO126oys8Cs9UZH+odOUZ4=";
  };
in {
  # Separate CPU-only llama-server instance for the fairy-tale-pipeline project's
  # story.json generation. Runs alongside the GPU gemma service on a different port.
  systemd.user.services.llama-cpp-story = {
    Unit = {
      Description = "llama.cpp inference server (CPU, Qwen2.5-32B story generation)";
      After = ["default.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.llama-cpp}/bin/llama-server"
        "--model ${qwen-story-model}"
        "--alias qwen32b-story"
        "--host 127.0.0.1"
        "--port 8090"
        "--threads 6"
        "--ctx-size 16384"
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
      ];
      MemoryMax = "28G";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
