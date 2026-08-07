#!/usr/bin/env bash
# vulnix False-Positive Triage
#
# Runs vulnix against the local system closure, then for every derivation it
# flags, inspects the derivation's build inputs for signals that indicate a
# nixpkgs name collision with an unrelated package (Rust crate vendored via
# cargo, Haskell build inputs, Haskell-style 4-component PVP versions).
#
# This does NOT modify the whitelist automatically. It prints candidates —
# each one still needs manual confirmation (see the "Verify with" comment at
# the top of .github/vulnix-whitelist.toml) before being added there.
#
# Usage: tools/scripts/vulnix-triage.sh [extra vulnix args...]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIRROR="https://mirror.cveb.in/nvd/json/cve/2.0/"
WHITELIST="${REPO_ROOT}/.github/vulnix-whitelist.toml"
FINDINGS_JSON="$(mktemp)"
trap 'rm -f "$FINDINGS_JSON"' EXIT

echo "Running vulnix --system (this can take a while on a cold cache)..." >&2
vulnix -j --system -m "$MIRROR" -w "$WHITELIST" "$@" >"$FINDINGS_JSON" || true

total=$(jq 'length' "$FINDINGS_JSON")
echo "Triaging ${total} finding(s)..." >&2
echo

suspect_count=0
while IFS= read -r drv; do
  name=$(basename "$drv" .drv)
  inputs=$(nix derivation show "$drv" 2>/dev/null | jq -r '.[].inputDrvs | keys[]?' || true)

  reason=""
  if grep -qE '/crate-[^/]+\.drv$' <<<"$inputs"; then
    reason="Rust crate vendored via cargo (crate-*.drv input) — crate version scheme unrelated to any C library of the same name"
  elif grep -qiE '/(ghc-|cabal-|hackage2nix)' <<<"$inputs"; then
    reason="Haskell build input present"
  elif [[ $name =~ -[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z].*)?$ ]]; then
    reason="4-component version suffix (Haskell PVP-style, e.g. 3.2.8.0) — check it's not a real 4-part upstream version first"
  fi

  if [ -n "$reason" ]; then
    suspect_count=$((suspect_count + 1))
    echo "SUSPECT: ${name}"
    echo "  reason: ${reason}"
    echo "  drv:    ${drv}"
    echo "  verify: nix derivation show ${drv} | jq '.[].env.pname, .[].env.version'"
    echo
  fi
done < <(jq -r '.[].derivation' "$FINDINGS_JSON" | sort -u)

echo "----------------------------------------------------------------------"
echo "${suspect_count} of ${total} finding(s) flagged for manual review."
echo "None of this was added to ${WHITELIST} — verify each one, then edit it by hand."
