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
      commit_message_model = {
        provider = "local";
        model = "Qwen2.5-Coder-7B";
      };
    };

    language_models = {
      anthropic.available_models = [
        {
          name = "claude-3-5-sonnet-latest";
          display_name = "Claude 3.5 Sonnet";
          max_tokens = 200000;
        }
        {
          name = "claude-3-opus-latest";
          display_name = "Claude 3 Opus";
          max_tokens = 200000;
        }
      ];
      google.available_models = [
        {
          name = "gemini-1.5-pro-latest";
          display_name = "Gemini 1.5 Pro";
          max_tokens = 2000000;
        }
        {
          name = "gemini-1.5-flash-latest";
          display_name = "Gemini 1.5 Flash";
          max_tokens = 1000000;
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
