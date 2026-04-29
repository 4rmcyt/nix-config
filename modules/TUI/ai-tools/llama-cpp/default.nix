{
  pkgs,
  lib,
  config,
  ...
}: let
  llama-cpp-cuda = pkgs.llama-cpp.override {
    cudaSupport = true;
  };
  gemma-model = pkgs.fetchurl {
    url = "https://huggingface.co/bartowski/google_gemma-4-E4B-it-GGUF/resolve/main/google_gemma-4-E4B-it-Q4_K_M.gguf";
    hash = "sha256-bfvbD/+CAl74im/5EvkdFB9yK12V8U1hsQ8OCIORhcg=";
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
        "--model ${gemma-model}"
        "--host 127.0.0.1"
        "--port 8080"
        "--n-gpu-layers 99"
        "--ctx-size 16384"
        "--webui-mcp-proxy"
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
