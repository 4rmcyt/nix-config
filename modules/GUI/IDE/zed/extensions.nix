{pkgs, ...}: {
  programs.zed-editor = {
    extraPackages = with pkgs; [
      python3Packages.python-lsp-server
      python3Packages.black
      ruff
      uv
    ];

    extensions = [
      "basher"
      "bearded"
      "claude"
      "docker-compose"
      "dockerfile"
      "gemini"
      "log"
      "material-icon-theme"
      "mcp-server-github"
      "nix"
      "python"
      "ruff"
      "terraform"
      "toml"
    ];
  };
}
