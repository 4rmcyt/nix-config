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

  networking.firewall.allowedTCPPorts = [8080];
}
