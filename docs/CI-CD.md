# CI/CD Pipeline

GitHub Actions workflows in [.github/workflows/](../.github/workflows/), composite actions in [.github/actions/](../.github/actions/). Currently **disabled at the repo level** — the files below describe the intended behavior for whenever Actions are turned back on.

## Layout

`ci.yml` is a thin orchestrator — it contains no build/check logic itself, only a `needs:` graph of jobs that each call a separate reusable workflow (`uses: ./.github/workflows/<file>.yml`). This is deliberate: a job that calls a reusable workflow still participates in `needs:` as a single node (its result rolls up from every job inside the called workflow), so splitting into files costs nothing in terms of gating and buys a lot in terms of "what does this actually do" being answerable by opening one small file instead of scrolling a 500-line one.

```
ci.yml
  ├─ flake-lock-update.yml   (schedule/workflow_dispatch only: nix flake update, commit + push)
  ├─ validate.yml            (needs: flake-lock-update; fmt + flake check — both non-blocking)
  ├─ security-checks.yml     (parallel with validate; 4 internal jobs, all must pass — gates the build)
  ├─ reusable-build.yml      (needs: validate + security-checks; matrix over every host)
  ├─ vulnix-scan.yml         (schedule/workflow_dispatch only, independent of the build gate)
  └─ workflow-summary        (inline job in ci.yml; needs everything; Telegram summary)
        │
        ▼ workflow_run: completed
logging.yml (workflow_run after CI)
  ├─ ships one structured per-job event to Loki always (dashboard)
  └─ ships the full per-line log of any failed job to Loki (debugging)
```

Two composite actions remove the boilerplate that used to be copy-pasted into every job:

| Action | Replaces |
|---|---|
| `.github/actions/setup-nix` | `cachix/install-nix-action` + `DeterminateSystems/magic-nix-cache-action`, with a shared baseline `nix.conf` (flakes, `accept-flake-config`, SSL cert path) and an `extra-nix-config` input for job-specific perf/cache tuning. |
| `.github/actions/notify-telegram` | `appleboy/telegram-action` with `to`/`token`/`format` fixed, `message` as the only input — one place to bump the action version or change the notification mechanism later. |

Both are local composite actions (`uses: ./.github/actions/<name>`), which means any job step using them must have already run `actions/checkout` — local action refs resolve from the checked-out workspace, not the repo on GitHub.

`flake-lock-update.yml` pushes with the default `GITHUB_TOKEN`. That push does **not** itself re-trigger `ci.yml`'s `push` trigger (GitHub doesn't fire `push`-triggered workflows off `GITHUB_TOKEN`-authored pushes) — a non-issue here because `flake-lock-update` runs as part of the *same* `ci.yml` run via `needs:`, not by re-triggering. `logging.yml` uses `workflow_run` (not `push`) specifically so it reliably fires regardless of how the upstream `CI` run started.

## ci.yml jobs

| Job | Runs when | Calls |
|---|---|---|
| `flake-lock-update` | `schedule` or `workflow_dispatch` only | `flake-lock-update.yml` — `nix flake update`, commits + pushes `flake.lock` to `main`. Skipped on `push`/`pull_request` so PR builds never get an unrelated auto-commit. Exposes `changes_detected` output. |
| `validate` | always (needs `flake-lock-update`, proceeds if it was skipped) | `validate.yml` — checks out (picking up the just-committed lock on schedule runs), re-runs `nix flake update` in-memory for PR/push runs, validates flake metadata, runs `nix fmt -- --ci` and `nix flake check` — both `continue-on-error: true` by design: a formatting or flake-check failure doesn't fail the job or block the build. `nix fmt` also runs `statix`/`deadnix` (wired into `treefmt.nix`) — same non-blocking treatment, intentional. Takes `flake_lock_changed` as input (from `flake-lock-update`'s output) to decide whether to run `nix flake check` even when its own in-memory update found nothing new. |
| `security-checks` | always, parallel with `validate` | `security-checks.yml` — see below. Hard gate: `build-and-check-systems` needs this to succeed. |
| `build-and-check-systems` | needs `validate` + `security-checks` | `reusable-build.yml` — matrix build of every real `nixosConfigurations` host: `desktop`, `homeserver`, `matebook`, `gcp-relay`. |
| `vulnix-scan` | `schedule` or `workflow_dispatch` only, independent of the build gate | `vulnix-scan.yml` — see below. |
| `workflow-summary` | push to `main`, not on PR | Inline job (not split out — it's just two Telegram notifications reading `needs.*.result`/`needs.security-checks.outputs.*`). |

**Host matrix caveat:** kept in sync with `parts/hosts/*/configuration.nix` by hand — no automatic derivation. Current hosts: `desktop`, `homeserver`, `matebook`, `router`, `gcp-relay` (flake attribute is `gcp-relay`, not `gcp`). `router` is intentionally excluded — not currently in use.

## security-checks.yml

Bundles four independent, parallel jobs — all four must pass for `build-and-check-systems` to start. Because the caller only sees `security-checks` as one job, a final `results` job inside this file re-exposes each check's individual `needs.<job>.result` as a workflow output (`trivy_result`, `secret_scan_result`, `sops_result`, `syntax_result`), so `workflow-summary` in `ci.yml` can still print an itemized pass/fail list instead of just one aggregate bit.

| Job | What it does |
|---|---|
| `trivy-scan` | `aquasecurity/trivy-action` filesystem scan (CRITICAL/HIGH), `exit-code: "1"` so findings actually fail the job; uploads SARIF to the GitHub Security tab. Mostly exercises Trivy's IaC/misconfig scanner against `infra/tf/gcp-relay/*.tf` and the k3s/argocd manifests under `modules/services/` — this repo has no `package.json`/`go.mod`/etc. for Trivy's dependency-CVE scanning to bite on. |
| `secret-scan` | TruffleHog, `--only-verified`, **no explicit `base`/`head`** — the action picks the right diff mode per event itself (PR diff / push before-after / full scan for schedule & dispatch). Passing explicit `base`/`head` that resolve to the same commit — which happens on every non-PR run — makes the action hard-fail instead of scanning; don't reintroduce that. |
| `sops-validation` | Every file under `secrets/` (not just `*.yaml/*.yml/*.json` — sops also produces `.env`/dotenv, binary/JSON-wrapped, and other formats) must contain one of `"sops":` / `^sops:` / `sops_mac=`, matching the marker sops actually writes for each output format. `radicale_users.txt` is allow-listed (currently a 0-byte placeholder — verify it's still needed). |
| `syntax-validation` | `yq eval` on every `*.yaml`/`*.yml` outside `secrets/`; `shellcheck` on every `*.sh`; `terraform fmt -check` on every directory containing `*.tf`; a grep-based check for unpinned `fetchTarball`/`fetchurl`/`fetchGit` calls in `*.nix` (no `sha256`/`hash`/`narHash`/`rev` within 8 lines of the call — coarse heuristic, review flagged hits by hand). No Nushell check — the repo has zero `.nu` files (shell is zsh). |

## reusable-build.yml

Called only by `ci.yml`'s `build-and-check-systems` matrix (`workflow_call`). Per system: checkout, `setup-nix`, `nix flake update` (in-memory, independent of `flake-lock-update`), Cachix push (only on `main`), Home Manager config validation, `nix build .#nixosConfigurations.<system>.config.system.build.toplevel`. No `vulnix` here — see `vulnix-scan.yml` for why it was pulled out.

## vulnix-scan.yml

Scans a **built Nix closure** against NVD CVEs — different target from Trivy (which scans repo *files*, before anything is built). `vulnix` was originally wired into `reusable-build.yml`, running once per host, in parallel, on every push/PR (4x per commit). That turned out to be a bad idea in practice: a cold-cache `vulnix` run downloads and parses **~5 years of NVD archives with no progress output**, confirmed by running `vulnix --system` locally and watching it hang silently for several minutes — this is documented, expected `vulnix` behavior (`doc/vulnix.1.md`: *"Invoking vulnix with an empty cache directory can take quite a while..."*), not a misconfiguration. Running that 4x in parallel on every commit was slow and risked NVD rate-limiting (5 req/30s unauthenticated).

Now it's `schedule`/`workflow_dispatch` only, scans a single representative host (`desktop` — broadest package set of the fleet), and is completely decoupled from the push/PR build gate. `~/.cache/vulnix` is cached across CI runs the same way as before (ISO-week key, falling back to the previous week's cache on a miss), so only the very first-ever run pays the full 5-year download — trigger `workflow_dispatch` once manually to warm that cache ahead of the nightly cron rather than let the first scheduled run eat it. Locally, the cache persists in `~/.cache/vulnix` on whatever machine runs it (already warmed on `desktop` after a manual `vulnix --system` run) — same mechanism, not shared between the two environments.

`vulnix` itself is also installed system-wide via `modules/base/common-packages/default.nix` for ad-hoc local scans (`vulnix --system`, `vulnix result/`, etc.).

## logging.yml

Fires on `workflow_run: [CI]` completion. For each job in the run, via `gh api /repos/{repo}/actions/runs/{run_id}/jobs`:

1. **Always**: ships one structured JSON event (`workflow`, `job_name`, `conclusion`, `duration_seconds`, `branch`, `run_number`, `actor`, `job_url` — low-cardinality fields as Loki stream labels, the rest in the JSON body for `| json` extraction) to the `job="github-actions"` stream. This is what a Grafana dashboard should query — e.g. `sum(count_over_time({job="github-actions"} | json | conclusion="success" [1d]))` for a success-rate panel, `quantile_over_time(0.95, {job="github-actions"} | json | unwrap duration_seconds [1d]))` for duration percentiles.
2. **Only on failure**: fetches that job's full log via `gh api /repos/{repo}/actions/jobs/{job_id}/logs` (plain text, not the zipped run-level export) and ships it line-by-line to the `job="github-actions-logs"` stream, for text search in Grafana Explore. Timestamps are anchored at job-completion time with a 1ns-per-line offset to keep entries ordered — not meant for precise timing analysis, just for keeping the log readable and searchable.

Previous version (`ship-logs-to-loki.yml`) slurped each job's entire raw log as a single opaque Loki entry with a "now" timestamp — no per-line structure, no queryable duration/conclusion fields, nothing dashboard-shaped. This version fixes both problems and only pays the "ship full log text" cost for jobs that actually failed.

### Grafana dashboard

`modules/monitoring/dashboards/github-actions.json` ("GitHub Actions Insights", uid `github-actions-insights`) is auto-provisioned by Grafana's dashboard provider (`modules/monitoring/default.nix`, picks up every `*.json` under `dashboards/`) — no separate registration needed when editing it. It queries the `job="github-actions"` stream from `logging.yml`: total/failed job counts, success rate, p95 duration, conclusion breakdown, status-over-time, per-job-name duration, and a recent-runs table. Filterable by `workflow`, `branch`, `job_name` template variables. The dashboard was previously built against the old `ship-logs-to-loki.yml` output (`status` as both a stream label and an unparseable JSON body) and never actually rendered real data — it's been rewritten to match the current `conclusion`/`duration_seconds` schema.

## Required secrets

`ci.yml` passes `secrets: inherit` to every reusable workflow it calls, so each one just declares what it needs in its own `on.workflow_call.secrets` block rather than the orchestrator having to enumerate them per call.

| Secret | Used by |
|---|---|
| `CACHIX_AUTH_TOKEN` | `reusable-build.yml` (Cachix push) |
| `TELEGRAM_CHAT_ID` / `TELEGRAM_BOT_TOKEN` | `flake-lock-update.yml`, `validate.yml`, `security-checks.yml`, `reusable-build.yml`, `vulnix-scan.yml`, `ci.yml`'s `workflow-summary` — all status notifications, via `.github/actions/notify-telegram` |
| `LOKI_ENDPOINT` / `LOKI_AUTH_TOKEN` | `logging.yml` |

`GITHUB_TOKEN` is the implicit default token everywhere else (checkout, SARIF upload, `gh api` for job/log fetching).
