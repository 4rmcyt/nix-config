{pkgs, ...}:
pkgs.mkShell {
  name = "cuda-dev";

  packages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cuda_cccl
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvcc

    gcc
    cmake
    pkg-config

    python3
    python3Packages.pip
    python3Packages.numpy
    python3Packages.torch-bin
    python3Packages.opencv4

    libGL
    libGLU
  ];

  shellHook = let
    wslLibPath =
      if pkgs.stdenv.isLinux && builtins.pathExists /usr/lib/wsl/lib
      then "/usr/lib/wsl/lib:"
      else "";
  in ''
    export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
    export LD_LIBRARY_PATH="${wslLibPath}${pkgs.cudaPackages.cudatoolkit}/lib:$LD_LIBRARY_PATH"

    echo "🔧 CUDA Development Environment"
    echo "CUDA Path: $CUDA_PATH"
    echo "NVIDIA Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null || echo 'Not available')"
    nvcc --version 2>/dev/null || echo "nvcc not in PATH"
  '';
}
