# CI/CD Pipeline

GitHub Actions workflows in [.github/workflows/](../.github/workflows/). Currently **disabled at the repo level** — the files below describe the intended behavior for whenever Actions are turned back on.

## Pipeline Chain

```
ci.yml (schedule 03:00 UTC / workflow_dispatch / push main / pull_request)
  └─ update-flake-lock   (schedule + workflow_dispatch only: nix flake update, commit + push)
  └─ validate             (needs: update-flake-lock; fmt check, flake check — both non-blocking)
  └─ trivy-scan           (needs: nothing, runs in parallel with validate; gates the build)
  └─ secret-scan          (parallel; gates the build)
  └─ sops-validation      (parallel; gates the build)
  └─ syntax-validation    (parallel; gates the build)
  └─ build-and-check-systems  (needs: validate + all four checks above; builds every host)
  └─ workflow-summary     (needs: everything; Telegram summary)
        │
        ▼ workflow_run: completed
logging.yml (workflow_run after CI)
  └─ ships one structured per-job event to Loki always (dashboard)
  └─ ships the full per-line log of any failed job to Loki (debugging)
```

`update-flake-lock` pushes with the default `GITHUB_TOKEN`. That push does **not** itself re-trigger `ci.yml`'s `push` trigger (GitHub doesn't fire `push`-triggered workflows off `GITHUB_TOKEN`-authored pushes) — this is a non-issue here because `update-flake-lock` is a job *inside* `ci.yml`, not a separate workflow; `validate` and the rest run via `needs:`, not by re-triggering. `logging.yml` uses `workflow_run` (not `push`) specifically so it reliably fires regardless of how the upstream `CI` run started.

## ci.yml

| Job | Runs when | What it does |
|---|---|---|
| `update-flake-lock` | `schedule` or `workflow_dispatch` only | `nix flake update`, commits + pushes `flake.lock` to `main`. Skipped on `push`/`pull_request` so PR builds never get an unrelated auto-commit. |
| `validate` | always (needs `update-flake-lock`, proceeds if it was skipped) | Checks out (picking up the just-committed lock on schedule runs), re-runs `nix flake update` in-memory for PR/push runs, validates flake metadata, runs `nix fmt -- --ci` and `nix flake check` — both `continue-on-error: true` by design: a formatting or flake-check failure doesn't fail the job or block the build. `nix fmt` also runs `statix`/`deadnix` (wired into `treefmt.nix`) — same non-blocking treatment, intentional. |
| `trivy-scan` | always, parallel with `validate` | `aquasecurity/trivy-action` filesystem scan (CRITICAL/HIGH), `exit-code: "1"` so findings actually fail the job; uploads SARIF to the GitHub Security tab. Mostly exercises Trivy's IaC/misconfig scanner against `infra/tf/gcp-relay/*.tf` and the k3s/argocd manifests under `modules/services/` — this repo has no `package.json`/`go.mod`/etc. for Trivy's dependency-CVE scanning to bite on. |
| `secret-scan` | always, parallel | TruffleHog, `--only-verified`, **no explicit `base`/`head`** — the action picks the right diff mode per event itself (PR diff / push before-after / full scan for schedule & dispatch). Passing explicit `base`/`head` that resolve to the same commit — which happens on every non-PR run — makes the action hard-fail instead of scanning; don't reintroduce that. |
| `sops-validation` | always, parallel | Every file under `secrets/` (not just `*.yaml/*.yml/*.json` — sops also produces `.env`/dotenv, binary/JSON-wrapped, and other formats) must contain one of `"sops":` / `^sops:` / `sops_mac=`, matching the marker sops actually writes for each output format. `radicale_users.txt` is allow-listed (currently a 0-byte placeholder — verify it's still needed). |
| `syntax-validation` | always, parallel | `yq eval` on every `*.yaml`/`*.yml` outside `secrets/`; `shellcheck` on every `*.sh`; `terraform fmt -check` on every directory containing `*.tf`; a grep-based check for unpinned `fetchTarball`/`fetchurl`/`fetchGit` calls in `*.nix` (no `sha256`/`hash`/`narHash`/`rev` within 8 lines of the call — coarse heuristic, review flagged hits by hand). No Nushell check — the repo has zero `.nu` files (shell is zsh). |
| `build-and-check-systems` | needs `validate` + all four checks above | Matrix build of every real `nixosConfigurations` host via `reusable-build.yml`: `desktop`, `homeserver`, `matebook`, `gcp-relay`. |
| `workflow-summary` | push to `main`, not on PR | Telegram summary of the run (pass or fail, itemized per check). |

**Host matrix caveat:** kept in sync with `parts/hosts/*/configuration.nix` by hand — no automatic derivation. Current hosts: `desktop`, `homeserver`, `matebook`, `router`, `gcp-relay` (flake attribute is `gcp-relay`, not `gcp`). `router` is intentionally excluded — not currently in use.

## reusable-build.yml

Called only by `ci.yml`'s `build-and-check-systems` matrix (`workflow_call`). Per system: checkout, install Nix, Magic Nix Cache, `nix flake update` (in-memory, independent of `update-flake-lock`), Cachix push (only on `main`), Home Manager config validation, `nix build .#nixosConfigurations.<system>.config.system.build.toplevel`, then **`vulnix`** against the built `result` closure — scans actual package versions in the closure against NVD CVEs, non-blocking (CVE feeds change daily, shouldn't block a build), with a weekly-keyed cache of the NVD feed (`~/.cache/vulnix`) to avoid re-downloading it on every run. `vulnix` is also installed system-wide via `modules/base/common-packages/default.nix` for ad-hoc local scans.

Trivy vs. vulnix — different targets, not redundant: Trivy scans repo *files* (IaC configs, manifests) before anything is built; vulnix scans the *actual built closure* (real package versions that will run on the host) after the build.

## logging.yml

Fires on `workflow_run: [CI]` completion. For each job in the run, via `gh api /repos/{repo}/actions/runs/{run_id}/jobs`:

1. **Always**: ships one structured JSON event (`workflow`, `job_name`, `conclusion`, `duration_seconds`, `branch`, `run_number`, `actor`, `job_url` — low-cardinality fields as Loki stream labels, the rest in the JSON body for `| json` extraction) to the `job="github-actions"` stream. This is what a Grafana dashboard should query — e.g. `sum(count_over_time({job="github-actions"} | json | conclusion="success" [1d]))` for a success-rate panel, `quantile_over_time(0.95, {job="github-actions"} | json | unwrap duration_seconds [1d]))` for duration percentiles.
2. **Only on failure**: fetches that job's full log via `gh api /repos/{repo}/actions/jobs/{job_id}/logs` (plain text, not the zipped run-level export) and ships it line-by-line to the `job="github-actions-logs"` stream, for text search in Grafana Explore. Timestamps are anchored at job-completion time with a 1ns-per-line offset to keep entries ordered — not meant for precise timing analysis, just for keeping the log readable and searchable.

Previous version (`ship-logs-to-loki.yml`) slurped each job's entire raw log as a single opaque Loki entry with a "now" timestamp — no per-line structure, no queryable duration/conclusion fields, nothing dashboard-shaped. This version fixes both problems and only pays the "ship full log text" cost for jobs that actually failed.

### Grafana dashboard

`modules/monitoring/dashboards/github-actions.json` ("GitHub Actions Insights", uid `github-actions-insights`) is auto-provisioned by Grafana's dashboard provider (`modules/monitoring/default.nix`, picks up every `*.json` under `dashboards/`) — no separate registration needed when editing it. It queries the `job="github-actions"` stream from `logging.yml`: total/failed job counts, success rate, p95 duration, conclusion breakdown, status-over-time, per-job-name duration, and a recent-runs table. Filterable by `workflow`, `branch`, `job_name` template variables. The dashboard was previously built against the old `ship-logs-to-loki.yml` output (`status` as both a stream label and an unparseable JSON body) and never actually rendered real data — it's been rewritten to match the current `conclusion`/`duration_seconds` schema.

## Required secrets

| Secret | Used by |
|---|---|
| `CACHIX_AUTH_TOKEN` | `reusable-build.yml` (Cachix push) |
| `TELEGRAM_CHAT_ID` / `TELEGRAM_BOT_TOKEN` | `ci.yml`, `reusable-build.yml`, for status notifications |
| `LOKI_ENDPOINT` / `LOKI_AUTH_TOKEN` | `logging.yml` |

`GITHUB_TOKEN` is the implicit default token everywhere else (checkout, SARIF upload, `gh api` for job/log fetching).
