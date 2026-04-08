{
  config,
  lib,
  ...
}: let
  systemPrompts = import ../../../TUI/ai-tools/system-prompt;
in {
  programs.zed-editor.userSettings = {
    features.copilot = false;

    assistant = {
      version = "2";
      default_model = {
        provider = "local";
        model = "google_gemma-4-E4B-it-Q4_K_M";
      };
    };

    agent = {
      default_model = {
        provider = "local";
        model = "google_gemma-4-E4B-it-Q4_K_M";
      };
      favorite_models = [
        {
          provider = "local";
          model = "google_gemma-4-E4B-it-Q4_K_M";
        }
        {
          provider = "google";
          model = "gemini-2.0-flash-thinking-exp-01-21";
        }
      ];
      always_allow_tool_actions = false;
      system_prompt = systemPrompts.llm lib config.programs.mcp.servers;
    };

    language_models = {
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
              name = "google_gemma-4-E4B-it-Q4_K_M";
              display_name = "Gemma 4 E4B (Local)";
              max_tokens = 65536;
            }
          ];
        };
      };
    };
  };
}
