_: {
  # Continue extension configuration (YAML format - required by newer Continue versions)
  home.file.".continue/config.yaml".text = ''
    name: Local Config
    version: 1.0.0
    schema: v1

    models:
      - name: gemini-2.5-pro
        provider: google
        title: Gemini 2.5 Pro
        model: gemini-2.5-pro

      - name: gemini-2.5-flash
        provider: google
        title: Gemini 2.5 Flash
        model: gemini-2.5-flash

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

      - name: terraform
        command: npx
        args: ["-y", "terraform-mcp-server"]

      - name: kubernetes
        command: uvx
        args: ["-y", "mcp-server-kubernetes"]

      - name: memory
        command: npx
        args: ["-y", "@modelcontextprotocol/server-memory"]

      - name: fetch
        command: npx
        args: ["-y", "@modelcontextprotocol/server-fetch"]

      - name: chrome-devtools
        command: npx
        args: ["-y", "chrome-devtools-mcp@latest"]

      - name: llama-cpp
        command: npx
        args: ["-y", "mcp-server-openai", "--base-url", "http://127.0.0.1:8080/v1", "--api-key", "not-needed", "--model", "glm-4.7-flash"]
  '';
}
