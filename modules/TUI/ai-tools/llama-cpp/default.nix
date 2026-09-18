{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: let
  # Built from HM's own pkgs (unfree CUDA allowed there) rather than the fork's flake `packages.cuda`.
  ik-llama-cpp-cuda =
    (pkgs.callPackage "${inputs.ik-llama-cpp}/.devops/nix/package.nix" {useCuda = true;}).overrideAttrs
    (old: {
      # RTX 3050 only (sm_86); the default builds every capability.
      cmakeFlags = (old.cmakeFlags or []) ++ ["-DCMAKE_CUDA_ARCHITECTURES=86"];
    });
  gemma-model = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-UD-Q4_K_XL.gguf";
    hash = "sha256-MNHnlJWXo0RnJgZOgLh2/Rtcukqm7sU9J6+kIOcx+zY=";
  };
  backendPort = 8092;
in {
  home.packages = [ik-llama-cpp-cuda];

  # :8080 socket -> socket-proxyd (exits after 15 min idle) -> backend on :8092 (StopWhenUnneeded), frees VRAM when idle.
  systemd.user.sockets.llama-cpp = {
    Unit = {
      Description = "ik_llama.cpp inference server socket";
      ConditionPathExists = "/dev/nvidiactl";
    };
    Socket.ListenStream = "127.0.0.1:8080";
    Install.WantedBy = ["sockets.target"];
  };

  systemd.user.services.llama-cpp = {
    Unit = {
      Description = "ik_llama.cpp inference server idle proxy";
      Requires = ["llama-cpp-backend.service" "llama-cpp.socket"];
      After = ["llama-cpp-backend.service" "llama-cpp.socket"];
    };
    Service = {
      Type = "notify";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=15min 127.0.0.1:${toString backendPort}";
    };
  };

  systemd.user.services.llama-cpp-backend = {
    Unit = {
      Description = "ik_llama.cpp inference server";
      StopWhenUnneeded = true;
    };

    Service = {
      Type = "simple";
      ExecStart = lib.concatStringsSep " " [
        "${ik-llama-cpp-cuda}/bin/llama-server"
        "--model ${gemma-model}"
        "--alias gemma-local"
        "--host 127.0.0.1"
        "--port ${toString backendPort}"
        "--n-gpu-layers 99"
        "--ctx-size 16384"
        "--webui-mcp-proxy"
        "--reasoning off"
        "--flash-attn on"
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
      ];
      # Hold the proxy back until the model is loaded; socket-proxyd refuses if the backend isn't listening yet.
      ExecStartPost = "${pkgs.curl}/bin/curl -fs --retry 150 --retry-delay 2 --retry-connrefused http://127.0.0.1:${toString backendPort}/health";
      TimeoutStartSec = "300";
      Environment = [
        "CUDA_VISIBLE_DEVICES=0"
        "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/cudatoolkit/lib"
      ];
      MemoryMax = "16G";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.user.services.mcp-proxy = {
    Unit = {
      Description = "MCP proxy (stdio → SSE) for llama-server";
      After = ["default.target"];
      ConditionPathExists = "%h/.config/mcp/mcp.json";
    };

    Service = {
      Type = "simple";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.mcp-proxy}/bin/mcp-proxy"
        "--port 8081"
        "--host 127.0.0.1"
        "--named-server-config ${config.home.homeDirectory}/.config/mcp/mcp.json"
        "--stateless"
        "--allow-origin http://127.0.0.1:8080"
        "--allow-origin http://localhost:8080"
      ];
      # mcp-python-interpreter wrapper uses realpath/dirname — ensure coreutils in PATH
      Environment = ["PATH=${lib.makeBinPath (with pkgs; [coreutils bash])}:/run/current-system/sw/bin"];
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
