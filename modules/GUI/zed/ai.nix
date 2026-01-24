_: {
  programs.zed-editor.userSettings = {
    features.copilot = false;

    assistant = {
      version = "2";
      default_model = {
        provider = "zed.dev";
        model = "claude-3-5-sonnet-latest";
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
          model = "gemini-3-pro-preview";
        }
      ];
      always_allow_tool_actions = false;
      system_prompt = "You are an expert software engineer. When solving complex problems, use the `sequentialthinking` tool to break down your thought process step-by-step before providing a final answer.";
    };

    language_models = {
      anthropic.available_models = [ ];
      openai.available_models = [ ];
      ollama.available_models = [ ];
      google.available_models = [
        {
          name = "gemini-3-pro-preview";
          display_name = "Gemini 3 Pro";
          max_tokens = 131072;
        }
        {
          name = "gemini-3-flash-preview";
          display_name = "Gemini 3 Flash";
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
        {
          name = "gemini-2.0-flash-thinking-exp-01-21";
          display_name = "Gemini 2.0 Flash Thinking";
          max_tokens = 131072;
        }
        {
          name = "gemini-1.5-flash-latest";
          display_name = "Gemini 1.5 Flash";
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
              max_tokens = 65536;
            }
          ];
        };
      };
    };
  };
}
