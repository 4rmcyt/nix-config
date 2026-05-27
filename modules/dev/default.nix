{pkgs, ...}: {
  home.packages = with pkgs; [
    # Runtime managers
    mise
    devenv

    # Node
    nodejs
    pnpm
    deno

    # Python
    uv
    pyenv
    (python3.withPackages (
      ps:
        with ps; [
          pip
          pydantic
          requests
          black
          pylint
          python-lsp-server
        ]
    ))

    # Infrastructure
    tenv
    supabase-cli
    wrangler

    # C/system
    gcc

    # CI/CD
    actionlint
  ];
}
