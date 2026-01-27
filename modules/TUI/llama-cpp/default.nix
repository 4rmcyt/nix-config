{pkgs, ...}: let
  llama-cpp-cuda = pkgs.llama-cpp.override {
    cudaSupport = true;
    blasSupport = true;
  };

  qwen-model = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q6_k.gguf";
    hash = "sha256-Rikd3qG/tgj+Y9mhkH7qaRi9qHp2Jlk+3Ev5fF/XP50=";
  };

  gpuServiceConfig = {
    DynamicUser = false;
    SupplementaryGroups = [
      "video"
      "render"
    ];
  };

  gpuEnvironment = {
    CUDA_VISIBLE_DEVICES = "0";
    LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  };
in {
  environment.systemPackages = [llama-cpp-cuda];

  systemd.services.llama-cpp = {
    description = "llama.cpp Server with Qwen2.5-Coder-7B";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig =
      gpuServiceConfig
      // {
        Type = "simple";
        ExecStart = ''
          ${llama-cpp-cuda}/bin/llama-server \
            --model ${qwen-model} \
            --n-gpu-layers 28 \
            --ctx-size 16384 \
            --batch-size 512 \
            --ubatch-size 128 \
            --cache-type-k q4_0 \
            --cache-type-v q4_0 \
            --flash-attn on \
            --no-mmap \
            --host 127.0.0.1 \
            --port 8080
        '';
        Restart = "on-failure";
        RestartSec = 5;
        MemoryMax = "24G";
        MemoryHigh = "20G";
        StateDirectory = "llama-cpp";
        CacheDirectory = "llama-cpp";
      };

    environment = gpuEnvironment;
  };

  networking.firewall.allowedTCPPorts = [8080];
}
