# CI/CD Pipeline

GitHub Actions workflows in [.github/workflows/](../.github/workflows/). Currently **disabled at the repo level** — the files below describe the intended behavior for whenever Actions are turned back on.

## Pipeline Chain

```
ci.yml (schedule 03:00 UTC / workflow_dispatch / push main / pull_request)
  └─ update-flake-lock   (schedule + workflow_dispatch only: nix flake update, commit + push)
  └─ validate             (needs: update-flake-lock; fmt check, flake check — both non-blocking)
  └─ build-and-check-systems  (needs: validate; builds every host via reusable-build.yml)
  └─ workflow-summary     (needs: validate, build-and-check-systems; Telegram summary)
        │
        ▼ workflow_run: completed
security.yml (workflow_run after CI / pull_request / workflow_dispatch / schedule Mon 06:00 UTC)
  └─ trivy-scan, secret-scan, sops-validation, syntax-validation
  └─ security-summary (needs: all four; Telegram summary)
        │
        ▼ workflow_run: completed
ship-logs-to-loki.yml (workflow_run after CI or Security Scanning)
  └─ downloads the run's logs, ships them to Loki on homeserver
```

`ci.yml` and `security.yml` are chained via `workflow_run`, not by both listening to `push` — a push made with the default `GITHUB_TOKEN` (e.g. by `update-flake-lock`) does not itself trigger other `push`-triggered workflows, so `workflow_run` is what makes the chain reliable regardless of how the run started.

## ci.yml

| Job | Runs when | What it does |
|---|---|---|
| `update-flake-lock` | `schedule` or `workflow_dispatch` only | `nix flake update`, commits + pushes `flake.lock` to `main` via `stefanzweifel/git-auto-commit-action`. Skipped on `push`/`pull_request` so PR builds never get an unrelated auto-commit. |
| `validate` | always (needs `update-flake-lock`, but proceeds if it was skipped) | Checks out (picking up the just-committed lock on schedule runs), re-runs `nix flake update` in-memory for PR/push runs, validates flake metadata, runs `nix fmt -- --ci` and `nix flake check` — both `continue-on-error: true`, so a formatting or flake-check failure does **not** fail the job or block the build. |
| `build-and-check-systems` | needs `validate` | Matrix build of every real `nixosConfigurations` host via `reusable-build.yml`: `desktop`, `homeserver`, `matebook`, `gcp-relay`. |
| `workflow-summary` | push to `main`, not on PR | Telegram summary of the run. |

**Host matrix caveat:** the matrix must be kept in sync with `parts/hosts/*/configuration.nix` by hand — there's no automatic derivation. Current hosts: `desktop`, `homeserver`, `matebook`, `router`, `gcp-relay` (note the flake attribute is `gcp-relay`, not `gcp`). `router` is intentionally excluded from CI — not currently in use.

**Known non-blocking design:** `validate`'s formatting/flake-check steps use `continue-on-error: true` on purpose — a broken `nix fmt` or `nix flake check` never fails the job or blocks `build-and-check-systems`. This is intentional (not a bug) — the real build step is the actual gate.

## security.yml

| Job | Checks |
|---|---|
| `trivy-scan` | `aquasecurity/trivy-action` filesystem scan (`scan-type: fs`, whole repo) for CRITICAL/HIGH/MEDIUM CVEs; uploads SARIF to the GitHub Security tab. **Caveat:** no `exit-code` is set, so Trivy never fails the step even when it finds vulnerabilities — the "Vulnerabilities Found" Telegram step is effectively dead unless the scanner action itself errors. Results only show up if someone checks the Security tab. |
| `secret-scan` | TruffleHog, `--only-verified`, diffing `base: <default branch>` against `head: HEAD`. **Caveat:** outside of `pull_request` runs, base and head are the same commit, so there's no diff to scan — this check is only meaningful on PRs. |
| `sops-validation` | Every file under `secrets/*.{yaml,yml,json}` must contain the literal string `sops:` — a cheap sanity check, not a real encryption/integrity validation. |
| `syntax-validation` | `nu-check` on every `*.nu` file; `yq eval` on every `*.yaml`/`*.yml` file outside `secrets/`. |
| `security-summary` | Telegram summary, push to `main` only. |

Triggered by `workflow_run` after `ci.yml` completes (checks out `github.event.workflow_run.head_sha`, i.e. the exact commit CI just validated), plus independently on `pull_request`, `workflow_dispatch`, and a weekly Monday 06:00 UTC full sweep.

## ship-logs-to-loki.yml

Fires on `workflow_run: [CI, Security Scanning]` completion. Downloads the run's logs via `gh api .../actions/runs/<id>/logs`, converts each job log into a Loki push payload (labeled with `workflow`, `repository`, `branch`, `status`, `job_name`), and POSTs it to `${{ secrets.LOKI_ENDPOINT }}/loki/api/v1/push` on the homeserver Grafana Loki instance.

## reusable-build.yml

Called only by `ci.yml`'s `build-and-check-systems` matrix (`workflow_call`). Per system: checkout, install Nix, Magic Nix Cache, `nix flake update` (in-memory, independent of `update-flake-lock`), Cachix push (only on `main`), Home Manager config validation, then `nix build .#nixosConfigurations.<system>.config.system.build.toplevel`.

## Required secrets

| Secret | Used by |
|---|---|
| `CACHIX_AUTH_TOKEN` | `reusable-build.yml` (Cachix push) |
| `TELEGRAM_CHAT_ID` / `TELEGRAM_BOT_TOKEN` | all workflows, for status notifications |
| `LOKI_ENDPOINT` / `LOKI_AUTH_TOKEN` | `ship-logs-to-loki.yml` |

`GITHUB_TOKEN` is the implicit default token everywhere else (checkout, SARIF upload, `gh api` for log download).
