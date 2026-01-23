{pkgs, ...}: let
  # Use nixpkgs llama-cpp with CUDA + BLAS for optimal performance
  llama-cpp-cuda = pkgs.llama-cpp.override {
    cudaSupport = true;
    blasSupport = true; # OpenBLAS for fast CPU layer computation
  };

  glm-model = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF/resolve/main/GLM-4.7-Flash-Q4_K_M.gguf";
    hash = "sha256-yQ0UIkP3AU7B+Ch9QGz76HUxZZ+1ph5elQOl5JPFJNI=";
  };

  # Qwen2.5-Coder 1.5B for autocomplete - small and fast
  qwen-coder-model = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf";
    hash = "sha256-zDJK8HDC7L/TJKMIhNL5Uaf/dWq6hcuBGm7ENpM7sEY=";
  };

  # Common systemd service config for GPU access
  gpuServiceConfig = {
    DynamicUser = true;
    SupplementaryGroups = ["video" "render"];
    DeviceAllow = [
      "/dev/nvidia0"
      "/dev/nvidiactl"
      "/dev/nvidia-modeset"
      "/dev/nvidia-uvm"
      "/dev/nvidia-uvm-tools"
      "/dev/dri/renderD129"
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

  # GLM-4.7-Flash for chat (port 8080)
  systemd.services.llama-cpp = {
    description = "llama.cpp Server with GLM-4.7-Flash-Q4 (Chat)";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig =
      gpuServiceConfig
      // {
        Type = "simple";
        ExecStart = ''
          ${llama-cpp-cuda}/bin/llama-server \
            --model ${glm-model} \
            --host 127.0.0.1 \
            --port 8080 \
            --n-gpu-layers 10 \
            --ctx-size 8192 \
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

  # Qwen2.5-Coder 1.5B for autocomplete (port 8081)
  systemd.services.llama-cpp-autocomplete = {
    description = "llama.cpp Server with Qwen2.5-Coder-1.5B (Autocomplete)";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig =
      gpuServiceConfig
      // {
        Type = "simple";
        ExecStart = ''
          ${llama-cpp-cuda}/bin/llama-server \
            --model ${qwen-coder-model} \
            --host 127.0.0.1 \
            --port 8081 \
            --n-gpu-layers 99 \
            --ctx-size 4096 \
            --threads 8 \
            --cont-batching \
            --no-mmap \
            --parallel 4
        '';
        Restart = "on-failure";
        RestartSec = 5;
        MemoryMax = "4G";
        MemoryHigh = "3G";
        StateDirectory = "llama-cpp-autocomplete";
        CacheDirectory = "llama-cpp-autocomplete";
      };

    environment = gpuEnvironment;
  };

  networking.firewall.allowedTCPPorts = [8080 8081];
}
