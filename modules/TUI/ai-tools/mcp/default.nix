{
  pkgs,
  config,
  lib,
  ...
}: let
  secretsFile = toString ./../../../../secrets/common.yaml;
  sops = lib.getExe pkgs.sops;
  yq = lib.getExe pkgs.yq;
  jq = lib.getExe pkgs.jq;

  staticServers = {
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
    filesystem = {
      type = "stdio";
      command = lib.getExe pkgs.mcp-server-filesystem;
      args = [
        "/etc/nixos"
        "/home/zeev/src"
      ];
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
    fetch = {
      type = "stdio";
      command = lib.getExe pkgs.mcp-server-fetch;
      args = [];
    };
    mcp-nixos = {
      type = "stdio";
      command = lib.getExe pkgs.mcp-nixos;
      args = [];
    };
    tavily = {
      type = "stdio";
      command = "${config.home.homeDirectory}/.local/bin/tavily-mcp-wrapped";
      args = [];
    };
  };

  staticMcpJson = pkgs.writeText "mcp-static.json" (builtins.toJSON {mcpServers = staticServers;});
in {
  home.packages = with pkgs; [
    nodejs
    uv
  ];

  home.activation.mcpConfig = lib.hm.dag.entryAfter ["writeBoundary" "sops-nix"] ''
        mkdir -p "$HOME/.config/mcp"
        mkdir -p "$HOME/.local/bin"

        export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

        GITHUB_PAT="$(${sops} -d ${secretsFile} | ${yq} -r '.git_access_token')"
        TAVILY_KEY="$(${sops} -d ${secretsFile} | ${yq} -r '.tavily_api_key')"
        FIZZY_TOKEN="$(${sops} -d ${secretsFile} | ${yq} -r '.fizzy_access_token')"

        # Generate final mcp.json with HTTP entries
        ${jq} --arg gh "$GITHUB_PAT" --arg fizzy "$FIZZY_TOKEN" \
          '.mcpServers.github = {"type":"http","url":"https://api.githubcopilot.com/mcp/x/all","headers":{"Authorization":"Bearer \($gh)"}} |
           .mcpServers.fizzy = {"type":"http","url":"https://fizzy.fabric.pro/mcp","headers":{"Authorization":"Bearer \($fizzy)"}} |
           .mcpServers.supabase = {"type":"http","url":"https://mcp.supabase.com/mcp"}' \
          ${staticMcpJson} > "$HOME/.config/mcp/mcp.json"
        chmod 600 "$HOME/.config/mcp/mcp.json"

        # Tavily wrapper
        cat > "$HOME/.local/bin/tavily-mcp-wrapped" << EOF
    #!${pkgs.bash}/bin/bash
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    export TAVILY_API_KEY="$TAVILY_KEY"
    exec ${lib.getExe pkgs.tavily-mcp} "\$@"
    EOF
        chmod +x "$HOME/.local/bin/tavily-mcp-wrapped"

        # Symlink into project
        ln -sf "$HOME/.config/mcp/mcp.json" "$HOME/src/nix-config/.mcp.json"
  '';
}
