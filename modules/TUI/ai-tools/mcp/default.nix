{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  programs.mcp = {
    enable = true;
    servers = {
      fetch = {
        command = lib.getExe pkgs.mcp-server-fetch;
        args = [];
      };
      memory = {
        command = lib.getExe pkgs.mcp-server-memory;
        args = [];
      };
      sequential-thinking = {
        command = lib.getExe pkgs.mcp-server-sequential-thinking;
        args = [];
      };
      playwright = {
        command = lib.getExe pkgs.playwright-mcp;
        args = [];
      };
      tavily = {
        command = "${config.home.homeDirectory}/.local/bin/tavily-mcp-wrapped";
        args = [];
      };
      filesystem = {
        command = lib.getExe pkgs.mcp-server-filesystem;
        args = [
          "/etc/nixos"
          "/home/zeev/src"
        ];
      };
      mcp-nixos = {
        command = lib.getExe inputs.mcp-nixos.packages.${system}.default;
        args = [];
      };
      github = {
        command = "${config.home.homeDirectory}/.local/bin/github-mcp-wrapped";
        args = ["stdio"];
      };
      kubernetes = {
        command = lib.getExe pkgs.mcp-k8s-go;
        args = [];
      };
      python = {
        command = "${pkgs.uv}/bin/uvx";
        args = ["mcp-python-interpreter"];
      };
      grep-mcp = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "grep-mcp"
        ];
      };
    };
  };

  # Create wrapper scripts with decrypted secrets
  home.activation.mcpWrappers = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p "$HOME/.local/bin"

        # GitHub wrapper
        cat > "$HOME/.local/bin/github-mcp-wrapped" << 'EOF'
    #!/usr/bin/env bash
    export GITHUB_PERSONAL_ACCESS_TOKEN="$(${pkgs.sops}/bin/sops -d ${../../../../secrets/common.yaml} | ${pkgs.yq}/bin/yq -r '.git_access_token')"
    exec ${lib.getExe pkgs.github-mcp-server} "$@"
    EOF
        chmod +x "$HOME/.local/bin/github-mcp-wrapped"

        # Tavily wrapper
        cat > "$HOME/.local/bin/tavily-mcp-wrapped" << 'EOF'
    #!/usr/bin/env bash
    export TAVILY_API_KEY="$(${pkgs.sops}/bin/sops -d ${../../../../secrets/common.yaml} | ${pkgs.yq}/bin/yq -r '.tavily_api_key')"
    exec ${lib.getExe pkgs.tavily-mcp} "$@"
    EOF
        chmod +x "$HOME/.local/bin/tavily-mcp-wrapped"
  '';
}
