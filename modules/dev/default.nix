{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Runtime/env managers
    mise
    devenv
    pyenv

    # Node
    pnpm
    deno

    # Python extras (base has python3+uv, this adds dev packages)
    (python3.withPackages (
      ps: with ps; [
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
    google-cloud-sdk

    # C/system
    gcc

    # CI/CD
    actionlint
  ];
}
