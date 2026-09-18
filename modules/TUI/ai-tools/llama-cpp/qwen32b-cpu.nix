{
  pkgs,
  lib,
  inputs,
  ...
}: let
  # package.nix builds with GGML_NATIVE=false; HAVE_FANCY_SIMD needs avx512{f,vl,bw,dq,vnni}, which GGML_AVX512* don't all enable.
  ik-llama-cpp = inputs.ik-llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    cmakeFlags =
      (old.cmakeFlags or [])
      ++ [
        "-DCMAKE_C_FLAGS=-march=znver4"
        "-DCMAKE_CXX_FLAGS=-march=znver4"
      ];
  });
  qwen-story-model = pkgs.fetchurl {
    url = "https://huggingface.co/bartowski/Qwen2.5-32B-Instruct-GGUF/resolve/main/Qwen2.5-32B-Instruct-Q4_K_M.gguf";
    hash = "sha256-Ll9trqGA28WfZaQGQelNOXO126oys8Cs9UZH+odOUZ4=";
  };
  backendPort = 8091;
in {
  # :8090 socket -> socket-proxyd (exits after 5 min idle) -> backend on :8091 (StopWhenUnneeded).
  systemd.user.sockets.llama-cpp-story = {
    Unit.Description = "ik_llama.cpp story server socket";
    Socket.ListenStream = "127.0.0.1:8090";
    Install.WantedBy = ["sockets.target"];
  };

  systemd.user.services.llama-cpp-story = {
    Unit = {
      Description = "ik_llama.cpp story server idle proxy";
      Requires = ["llama-cpp-story-backend.service" "llama-cpp-story.socket"];
      After = ["llama-cpp-story-backend.service" "llama-cpp-story.socket"];
    };
    Service = {
      Type = "notify";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:${toString backendPort}";
    };
  };

  # No Install: pulled in by the proxy, ~28G RAM.
  systemd.user.services.llama-cpp-story-backend = {
    Unit = {
      Description = "ik_llama.cpp inference server (CPU, Qwen2.5-32B story generation)";
      StopWhenUnneeded = true;
    };

    Service = {
      Type = "simple";
      ExecStart = lib.concatStringsSep " " [
        "${ik-llama-cpp}/bin/llama-server"
        "--model ${qwen-story-model}"
        "--alias qwen32b-story"
        "--host 127.0.0.1"
        "--port ${toString backendPort}"
        "--threads 6"
        "--ctx-size 16384"
        # default n_parallel=4 would reserve 4x the KV cache actually needed, since
        # generate_story.py only ever sends one request at a time.
        "--parallel 1"
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
      ];
      # Hold the proxy back until the model is loaded; socket-proxyd refuses if the backend isn't listening yet.
      ExecStartPost = "${pkgs.curl}/bin/curl -fs --retry 300 --retry-delay 2 --retry-connrefused http://127.0.0.1:${toString backendPort}/health";
      TimeoutStartSec = "900";
      # Real single-slot working set (~20G model + ctx-size 16384 q8_0 KV cache) sits
      # right at 28G once pages are touched, not the ~13G seen right after a fresh start.
      MemoryMax = "32G";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
