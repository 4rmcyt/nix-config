#!/usr/bin/env bash
# shellcheck disable=SC2016 # $m/$v/$h below are jq variables, not shell ones
# Bump Caddy plugins to the latest stable tag within their major, then refresh per-host withPlugins hashes.
# Usage: caddy-plugins-update.sh [--hashes-only] [host...]  (no hosts = every host in the JSON)
set -euo pipefail

hashes_only=false
if [[ ${1:-} == --hashes-only ]]; then
  hashes_only=true
  shift
fi

cd "$(git rev-parse --show-toplevel)"
json=modules/networking/caddy-plugins.json

update_json() {
  local tmp
  tmp=$(mktemp)
  jq "$@" "$json" >"$tmp"
  mv "$tmp" "$json"
}

bump_plugin() {
  local mod=$1 cur major tags latest newest
  cur=$(jq -r --arg m "$mod" '.plugins[$m]' "$json")
  major=$(cut -d. -f1 <<<"$cur")
  tags=$(git ls-remote --tags --refs "https://$mod" |
    sed 's#.*refs/tags/##' |
    grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' |
    sort -V)
  latest=$(grep -E "^${major}\." <<<"$tags" | tail -n1)
  newest=$(tail -n1 <<<"$tags")

  # Go v2+ modules change import path (/v2), so a major bump is a manual migration.
  if [[ $newest != "$latest" ]]; then
    echo "  ! $mod: new major $newest available (staying on $major)"
  fi

  if [[ -n $latest && $latest != "$cur" ]]; then
    echo "  $mod: $cur -> $latest"
    update_json --arg m "$mod" --arg v "$latest" '.plugins[$m] = $v'
  else
    echo "  $mod: $cur (up to date)"
  fi
}

refresh_hash() {
  local host=$1 attr out got
  attr=".#nixosConfigurations.${host}.config.services.caddy.package.src"
  if out=$(nix build --no-link "$attr" 2>&1); then
    echo "  $host: ok"
    return
  fi

  got=$(grep -oP 'got:\s+\Ksha256-\S+' <<<"$out" || true)
  if [[ -z $got ]]; then
    echo "$out" >&2
    echo "  $host: build failed without a hash mismatch" >&2
    exit 1
  fi

  echo "  $host: hash -> $got"
  update_json --arg h "$host" --arg v "$got" '.hosts[$h].hash = $v'
  nix build --no-link "$attr"
}

if ! $hashes_only; then
  echo "== plugins"
  for mod in $(jq -r '.plugins | keys[]' "$json"); do
    bump_plugin "$mod"
  done
fi

hosts=("$@")
if [[ ${#hosts[@]} -eq 0 ]]; then
  mapfile -t hosts < <(jq -r '.hosts | keys[]' "$json")
fi

echo "== hashes"
for host in "${hosts[@]}"; do
  refresh_hash "$host"
done
