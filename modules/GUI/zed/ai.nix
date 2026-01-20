_: {
  programs.zed-editor.userSettings = {
    # ===== AI Features =====
    features.copilot = false;

    assistant = {
      version = "2";
      default_model = {
        provider = "google";
        model = "gemini-2.5-pro";
      };
    };

    language_models = {
      google = {
        available_models = [
          {
            name = "gemini-2.5-pro";
            display_name = "Gemini 2.5 Pro";
            max_tokens = 1000000;
          }
        ];
      };
      ollama = {
        api_url = "http://localhost:11434";
        available_models = [
          {
            name = "qwen2.5-coder:7b";
            display_name = "Qwen 2.5 Coder 7B (Direct)";
            max_tokens = 32000;
          }
        ];
      };
      openai = {
        api_url = "http://127.0.0.1:8080/v1";
        available_models = [
          {
            name = "glm-4.7-flash";
            display_name = "GLM-4.7-Flash (Local)";
            max_tokens = 8192;
          }
        ];
      };
    };

    agent_servers = {
      "gemini" = {
        "ignore_system_version" = false;
      };
    };
  };
}
