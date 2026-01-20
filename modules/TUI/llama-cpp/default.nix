{
  pkgs,
  inputs,
  ...
}: let
  # Use llama-cpp from flake input with CUDA support
  llama-cpp-cuda = inputs.llama-cpp.packages.${pkgs.system}.cuda;

  # GLM-4.7-Flash GGUF model (Q4_K_M quantization - 30B MoE reasoning model)
  # Q4_K_M is ~17GB, fits in 64GB RAM with partial GPU offload
  glm-model = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF/resolve/main/GLM-4.7-Flash-Q4_K_M.gguf";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Update with correct hash after first build
  };
in {
  # Add llama-cpp with CUDA to system packages
  environment.systemPackages = [
    llama-cpp-cuda
  ];

  systemd.services.llama-cpp = {
    description = "llama.cpp Server with GLM-4.7-Flash-Q4";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${llama-cpp-cuda}/bin/llama-server \
          --model ${glm-model} \
          --host 127.0.0.1 \
          --port 8080 \
          --n-gpu-layers 20 \
          --ctx-size 8192 \
          --threads 12
      '';
      Restart = "on-failure";
      RestartSec = 5;

      # Security hardening
      DynamicUser = true;
      StateDirectory = "llama-cpp";
      CacheDirectory = "llama-cpp";

      # GPU access
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

    environment = {
      CUDA_VISIBLE_DEVICES = "0";
    };
  };

  networking.firewall.allowedTCPPorts = [8080];
}
