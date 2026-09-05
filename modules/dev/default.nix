{pkgs, ...}: {
  home.packages = with pkgs; [
    mise
    devenv
    pyenv

    pnpm
    deno

    # Python extras (base has python3+uv, this adds dev packages)
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

    tenv
    supabase-cli
    wrangler
    google-cloud-sdk
    gcc

    actionlint
    pre-commit
  ];
}
