{
  pkgs,
  lib,
  inputs,
  ...
}: let
  llama-cpp-cuda = inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.cuda.overrideAttrs {
    version = inputs.llama-cpp.shortRev or "unstable";
  };
  qwen-model = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q5_k_m.gguf";
    hash = "sha256-WGhE6sTW1jIWifAZLIqo5pzYYll0pcwtklsaAzZuTRY=";
  };
in {
  hardware.nvidia.powerManagement.enable = true;
  services.llama-cpp = {
    enable = true;
    package = llama-cpp-cuda;
    model = qwen-model;
    host = "127.0.0.1";
    port = 8080;
    extraFlags = [
      "--n-gpu-layers"
      "20"
      "--ctx-size"
      "16384"
      "--flash-attn"
      "on"
      "--cache-type-k"
      "q8_0"
      "--cache-type-v"
      "q8_0"
    ];
  };

  systemd.services.llama-cpp = {
    unitConfig.ConditionPathExists = "/dev/nvidiactl";

    serviceConfig = {
      SupplementaryGroups = [
        "video"
        "render"
      ];
      MemoryMax = "16G";
      DynamicUser = lib.mkForce false;
      StateDirectory = "llama-cpp";
    };

    environment = {
      CUDA_VISIBLE_DEVICES = "0";
      LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/cudatoolkit/lib";
    };
  };

  environment.etc."nvidia/nvidia-application-profiles-rc.d/hyprland.json".text = ''
    {
      "rules": [
        { "pattern": { "feature": "procname", "matches": ".Hyprland-wrapped" }, "profile": "Limit VRAM Buffer" }
      ],
      "profiles": [
        { "name": "Limit VRAM Buffer", "settings": [ { "k": "GLVidHeapReuseRatio", "v": 10 } ] }
      ]
    }
  '';
}
