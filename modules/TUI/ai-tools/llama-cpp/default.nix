{
  pkgs,
  lib,
  ...
}: let
  llama-cpp-cuda = pkgs.llama-cpp.override {
    cudaSupport = true;
  };
  qwen-model = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q5_k_m.gguf";
    hash = "sha256-WGhE6sTW1jIWifAZLIqo5pzYYll0pcwtklsaAzZuTRY=";
  };
in {
  home.packages = [llama-cpp-cuda];

  systemd.user.services.llama-cpp = {
    Unit = {
      Description = "llama.cpp inference server";
      After = ["default.target"];
      ConditionPathExists = "/dev/nvidiactl";
    };

    Service = {
      Type = "simple";
      ExecStart = lib.concatStringsSep " " [
        "${llama-cpp-cuda}/bin/llama-server"
        "--model ${qwen-model}"
        "--host 127.0.0.1"
        "--port 8080"
        "--n-gpu-layers 20"
        "--ctx-size 16384"
        "--flash-attn on"
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
      ];
      Environment = [
        "CUDA_VISIBLE_DEVICES=0"
        "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/cudatoolkit/lib"
      ];
      MemoryMax = "16G";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
