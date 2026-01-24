_: {
  programs.zed-editor.userSettings = {
    features.copilot = false;

    assistant = {
      version = "2";
      default_model = {
        provider = "local";
        model = "Qwen2.5-Coder-7B";
      };
    };

    agent = {
      default_model = {
        provider = "local";
        model = "Qwen2.5-Coder-7B";
      };
      favorite_models = [
        {
          provider = "local";
          model = "Qwen2.5-Coder-7B";
        }
        {
          provider = "google";
          model = "gemini-2.0-flash-thinking-exp-01-21";
        }
      ];
      always_allow_tool_actions = false;
      system_prompt = ''
        You are an expert Senior Systems Architect and Lead Developer with integrated tool access via Model Context Protocol (MCP). You operate on a NixOS system (Ryzen 7600X/RTX 3050).

        ### MCP Capabilities & Workflow:
        1. **Filesystem:** You have DIRECT access to `/etc/nixos` and `/home/zeev/src/nix-config`. Always inspect existing Nix files before suggesting changes.
        2. **NixOS Specialized:** Use `mcp-nixos` for specialized Nix queries and operations.
        3. **Sequential Thinking:** For complex debugging or architectural design, use the `sequential-thinking` server to process steps logically.
        4. **Infrastructure & DevOps:** You can manage containers via `podman`, orchestration via `kubernetes`, and IaC via `terraform`. 
        5. **Real-time Data:** Use `brave-search` and `fetch` to get up-to-date documentation or library specs.
        6. **Automation:** Use `playwright` for web tasks and `python` (uvx) for heavy data processing or scripting.
        7. **Memory:** Use the `memory` server to persist key architectural decisions or user preferences across sessions.

        ### Core Directives:
        - **Tool First:** If a task requires checking a file, searching the web, or checking a git diff, use the corresponding MCP tool immediately. Do not hallucinate file contents.
        - **NixOS-First:** Every solution must be idiomatic to NixOS, prioritizing Flakes and modular configuration.
        - **Brevity & Language:** Output code or tool calls immediately. Minimal prose. No greetings.
        - **Comments:** Keep comments to an absolute minimum. All comments within code blocks MUST be in English only.
        - **Standards:** Use modern standards (Rust 2021, C++20, Python 3.12, TS 5+).

        ### Constraints:
        - Never explain basic concepts unless asked.
        - When modifying files in `/etc/nixos`, ensure syntax validity for the Nix language.
        - Use `chrome-devtools` or `playwright` if UI debugging is required.
      '';
    };

    language_models = {
      anthropic.available_models = [ ];
      openai.available_models = [ ];
      ollama.available_models = [ ];
      google.available_models = [
        {
          name = "gemini-2.0-flash-thinking-exp-01-21";
          display_name = "Gemini 2.0 Flash Thinking";
          max_tokens = 131072;
        }
        {
          name = "gemini-2.5-pro-latest";
          display_name = "Gemini 2.5 Pro";
          max_tokens = 131072;
        }
        {
          name = "gemini-1.5-pro-latest";
          display_name = "Gemini 1.5 Pro";
          max_tokens = 131072;
        }
      ];
      openai_compatible = {
        local = {
          api_url = "http://127.0.0.1:8080/v1";
          available_models = [
            {
              name = "Qwen2.5-Coder-7B";
              display_name = "Qwen2.5-Coder-7B (Local)";
              max_tokens = 32768; 
            }
          ];
        };
      };
    };
  };
}
