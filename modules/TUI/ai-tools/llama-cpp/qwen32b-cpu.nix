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
  # Deliberately has no Install/WantedBy: a 32B model pins ~28G of RAM, so it must not
  # auto-start at login — generate_story.py starts/stops it itself.
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
        # default n_parallel=4 would reserve 4x the KV cache actually needed, since
        # generate_story.py only ever sends one request at a time.
        "--parallel 1"
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
        # Orphaned runs previously pinned ~12G of RAM for over an hour after the last
        # request; /health polls don't count as activity, so this won't reset on its own.
        "--sleep-idle-seconds 300"
      ];
      # Real single-slot working set (~20G model + ctx-size 16384 q8_0 KV cache) sits
      # right at 28G once pages are touched, not the ~13G seen right after a fresh start.
      MemoryMax = "32G";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
