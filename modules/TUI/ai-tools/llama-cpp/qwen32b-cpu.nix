{
  pkgs,
  lib,
  ...
}: let
  qwen-story-model = pkgs.fetchurl {
    url = "https://huggingface.co/bartowski/Qwen2.5-32B-Instruct-GGUF/resolve/main/Qwen2.5-32B-Instruct-Q4_K_M.gguf";
    hash = "sha256-Ll9trqGA28WfZaQGQelNOXO126oys8Cs9UZH+odOUZ4=";
  };
in {
  # On-demand CPU-only llama-server for the fairy-tale-pipeline project's
  # story.json generation. Deliberately has no Install/WantedBy: a 32B model
  # pins ~28G of RAM, so it must not auto-start at login. Start it only when
  # needed: `systemctl --user start llama-cpp-story` (the pipeline's
  # generate_story.py does this itself and stops it again afterwards).
  systemd.user.services.llama-cpp-story = {
    Unit = {
      Description = "llama.cpp inference server (CPU, Qwen2.5-32B story generation, on-demand)";
    };

    Service = {
      Type = "simple";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.llama-cpp}/bin/llama-server"
        "--model ${qwen-story-model}"
        "--alias qwen32b-story"
        "--host 127.0.0.1"
        "--port 8090"
        "--threads 6"
        "--ctx-size 16384"
        # generate_story.py only ever sends one request at a time; llama-server's
        # default n_parallel=4 slots each get a full --ctx-size KV cache (16384
        # tokens per slot), so it was reserving 4x the KV memory actually needed.
        "--parallel 1"
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
      ];
      MemoryMax = "28G";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
