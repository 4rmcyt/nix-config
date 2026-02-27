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
      memory = {
        type = "stdio";
        command = lib.getExe pkgs.mcp-server-memory;
        args = [];
      };
      sequential-thinking = {
        type = "stdio";
        command = lib.getExe pkgs.mcp-server-sequential-thinking;
        args = [];
      };
      playwright = {
        type = "stdio";
        command = lib.getExe pkgs.playwright-mcp;
        args = [];
      };
      tavily = {
        type = "stdio";
        command = "${config.home.homeDirectory}/.local/bin/tavily-mcp-wrapped";
        args = [];
      };
      filesystem = {
        type = "stdio";
        command = lib.getExe pkgs.mcp-server-filesystem;
        args = [
          "/etc/nixos"
          "/home/zeev/src"
        ];
      };
      mcp-nixos = {
        type = "stdio";
        command = lib.getExe inputs.mcp-nixos.packages.${system}.default;
        args = [];
      };
      github = {
        type = "stdio";
        command = "${config.home.homeDirectory}/.local/bin/github-mcp-wrapped";
        args = ["stdio"];
      };
      kubernetes = {
        type = "stdio";
        command = lib.getExe pkgs.mcp-k8s-go;
        args = [];
      };
      python = {
        type = "stdio";
        command = "${pkgs.uv}/bin/uvx";
        args = ["mcp-python-interpreter"];
      };
      claude-context = {
        type = "stdio";
        command = "${config.home.homeDirectory}/.local/bin/claude-context-mcp-wrapped";
        args = [];
      };
    };
  };

  # Symlink project .mcp.json to the HM-managed global config so it stays current after rebuilds
  home.file."src/nix-config/.mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mcp/mcp.json";

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

        # Claude Context (Zilliz) wrapper
        cat > "$HOME/.local/bin/claude-context-mcp-wrapped" << 'EOF'
    #!/usr/bin/env bash
    export MILVUS_ADDRESS="$(${pkgs.sops}/bin/sops -d ${../../../../secrets/common.yaml} | ${pkgs.yq}/bin/yq -r '.milvus_address')"
    export MILVUS_TOKEN="$(${pkgs.sops}/bin/sops -d ${../../../../secrets/common.yaml} | ${pkgs.yq}/bin/yq -r '.milvus_token')"
    export OPENAI_API_KEY="$(${pkgs.sops}/bin/sops -d ${../../../../secrets/common.yaml} | ${pkgs.yq}/bin/yq -r '.openai_api_key')"
    exec ${pkgs.nodejs}/bin/npx -y @zilliz/claude-context-mcp@latest "$@"
    EOF
        chmod +x "$HOME/.local/bin/claude-context-mcp-wrapped"
  '';
}
