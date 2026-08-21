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
        # Safety net for orphaned runs: if a caller starts this service and finds
        # it already active (see generate_story.py's llama_service_is_active
        # check), it never stops it -- that let this pin ~12G of RAM for over an
        # hour after its last request and drove the system into heavy swapping.
        # Unload the model+KV cache automatically after 5 minutes idle; /health
        # polls don't count as activity, so a script waiting on readiness won't
        # keep resetting this. First request after sleep just reloads it.
        "--sleep-idle-seconds 300"
      ];
      # 28G left ~444K of headroom in practice once the KV cache actually fills
      # in (n_slots=1 lowered the theoretical ceiling but the real single-slot
      # working set -- ~20G model + ctx-size 16384 q8_0 KV cache -- still sits
      # right at 28G once pages are touched, not the ~13G seen right after a
      # fresh start before the cache has filled).
      MemoryMax = "32G";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
