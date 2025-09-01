{ pkgs ? import <nixpkgs> { 
  config = { 
    allowUnfree = true; 
    cudaSupport = true; 
  }; 
}}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # CUDA development tools
    cudatoolkit
    cuda_cccl
    cuda_cudart
    cuda_nvcc
    
    # Development tools
    gcc
    cmake
    pkg-config
    
    # Python with CUDA packages
    python3
    python3Packages.pip
    python3Packages.numpy
    python3Packages.torch-bin  
    python3Packages.opencv4 
    
    # Other useful tools
    nsight-compute
    nvidia-driver
  ];

  shellHook = ''
    export CUDA_PATH=${pkgs.cudatoolkit}
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.cudatoolkit}/lib:$LD_LIBRARY_PATH"
    echo "CUDA development environment loaded"
    echo "CUDA Path: $CUDA_PATH"
    echo "NVIDIA Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits)"
    nvcc --version
  '';
}