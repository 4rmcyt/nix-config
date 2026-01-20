{lib, ...}: {
  # Continue extension configuration (YAML format - required by newer Continue versions)
  # Uses activation script to inject API key from sops at runtime
  home.activation.continueConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.continue"

    # Read API key from sops secret
    GEMINI_KEY=""
    if [[ -r /run/secrets/gemini_api_key ]]; then
      GEMINI_KEY=$(cat /run/secrets/gemini_api_key)
    fi

    cat > "$HOME/.continue/config.yaml" << EOF
name: Local Config
version: 1.0.0
schema: v1

models:
  - name: gemini-2.5-pro
    provider: gemini
    title: Gemini 2.5 Pro
    model: gemini-2.5-pro
    apiKey: $GEMINI_KEY

  - name: gemini-2.5-flash
    provider: gemini
    title: Gemini 2.5 Flash
    model: gemini-2.5-flash
    apiKey: $GEMINI_KEY

  - name: glm-local
    provider: openai
    title: GLM-4.7-Flash (Local)
    model: glm-4.7-flash
    apiBase: http://127.0.0.1:8080/v1
    apiKey: not-needed

tabAutocompleteModel:
  provider: openai
  title: GLM-4.7-Flash Autocomplete
  model: glm-4.7-flash
  apiBase: http://127.0.0.1:8080/v1
  apiKey: not-needed

mcpServers:
  - name: mcp-nixos
    command: nix
    args: ["run", "github:utensils/mcp-nixos", "--"]

  - name: filesystem
    command: npx
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/etc/nixos", "/home/zeev/src/nix-config"]

  - name: sequential-thinking
    command: npx
    args: ["-y", "@modelcontextprotocol/server-sequential-thinking"]

  - name: memory
    command: npx
    args: ["-y", "@modelcontextprotocol/server-memory"]

  - name: fetch
    command: uvx
    args: ["mcp-server-fetch"]

  - name: chrome-devtools
    command: npx
    args: ["-y", "chrome-devtools-mcp@latest"]
EOF
  '';
}
