{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [python312 uv gcc pkg-config];

  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libsndfile
    portaudio
    libGL
    libGLU
    glfw
    fontconfig
    freetype
    libx11
    libxrandr
    libxinerama
    libxcursor
    libxi
    libxext
    libxfixes
    libxcb
  ]);

  UV_PYTHON_DOWNLOADS = "never";
  UV_PYTHON = "python3.12";
}
