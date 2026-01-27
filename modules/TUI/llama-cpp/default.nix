{ pkgs, lib, ... }:
let
  llama-cpp-cuda = pkgs.llama-cpp.override {
    cudaSupport = true;
  };

  # Q5_K_M variant for optimal accuracy/VRAM balance
  qwen-model = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q5_k_m.gguf";
    hash = "sha256-WGhE6sTW1jIWifAZLIqo5pzYYll0pcwtklsaAzZuTRY="; # Replace with actual hash
  };

  gpuEnvironment = {
    CUDA_VISIBLE_DEVICES = "0";
    # Ensure drivers are visible to the binary
    LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/cudatoolkit/lib";
  };
in
{
  environment.systemPackages = [ llama-cpp-cuda ];

  systemd.services.llama-cpp = {
    description = "llama.cpp Server with Qwen2.5-Coder-7B-Q5_K_M";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      # Offload all 28 layers to GPU (GTX 3050)
      # Using lib.getExe for idiomatic path resolution
      ExecStart = ''
        ${lib.getExe llama-cpp-cuda} --server \
          --model ${qwen-model} \
          --n-gpu-layers 99 \
          --ctx-size 16384 \
          --standby-timeout 300 \
          --batch-size 512 \
          --ubatch-size 128 \
          --flash-attn \
          --cache-type-k q4_0 \
          --cache-type-v q4_0 \
          --host 127.0.0.1 \
          --port 8080
      '';

      # Permissions and Resource Control
      DynamicUser = false;
      SupplementaryGroups = [
        "video"
        "render"
      ];
      Restart = "on-failure";
      RestartSec = 5;

      # Memory limits for safety (System RAM)
      MemoryMax = "16G";
      MemoryHigh = "12G";

      StateDirectory = "llama-cpp";
      CacheDirectory = "llama-cpp";
    };

    environment = gpuEnvironment;
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
