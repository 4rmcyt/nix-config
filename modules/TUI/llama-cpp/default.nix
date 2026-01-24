{pkgs, ...}: let
  # Use nixpkgs llama-cpp with CUDA + BLAS for optimal performance
  llama-cpp-cuda = pkgs.llama-cpp.override {
    cudaSupport = true;
    blasSupport = true; # OpenBLAS for fast CPU layer computation
  };

  qwen-model = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf";
    hash = "sha256-UJKH94y01M9rOENzRzO5FLLBWOQ+Iqf0v16WOACJTTw=";
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
  environment.systemPackages = [
    llama-cpp-cuda
  ];

  # Qwen2.5-Coder-7B for chat (port 8080)
  systemd.services.llama-cpp = {
    description = "llama.cpp Server with Qwen2.5-Coder-7B (Chat)";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig =
      gpuServiceConfig
      // {
        Type = "simple";
        ExecStart = ''
          ${llama-cpp-cuda}/bin/llama-server \
            --model ${qwen-model} \
            --host 127.0.0.1 \
            --port 8080 \
            --n-gpu-layers 100 \
            --ctx-size 32768 \
            --threads 12 \
            --cont-batching \
            --no-mmap \
            --parallel 1
        '';
        Restart = "on-failure";
        RestartSec = 5;
        MemoryMax = "20G";
        MemoryHigh = "18G";
        StateDirectory = "llama-cpp";
        CacheDirectory = "llama-cpp";
      };

    environment = gpuEnvironment;
  };

  networking.firewall.allowedTCPPorts = [8080];
}
