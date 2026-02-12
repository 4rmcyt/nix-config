{
  claude = import ./claude-prompt.nix;
  gemini = import ./gemini-prompt.nix;
  llm = import ./llm-prompt.nix;
  base = import ./base-prompt.nix;
}
