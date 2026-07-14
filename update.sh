#!/usr/bin/env bash
# Regenerate sources.json with the latest Zed version and per-system hashes.
# Pin a version with: ./update.sh 1.10.3
set -euo pipefail
cd "$(dirname "$0")"

ver="${1:-$(curl -fsSL https://api.github.com/repos/zed-industries/zed/releases/latest | jq -r .tag_name | sed 's/^v//')}"
[ -n "$ver" ] && [ "$ver" != "null" ] || { echo "could not determine latest version" >&2; exit 1; }

# system -> release target
systems="x86_64-linux:x86_64"

json=$(jq -n --arg version "$ver" '{version: $version, systems: {}}')
for entry in $systems; do
  sys="${entry%%:*}"; target="${entry#*:}"
  url="https://github.com/zed-industries/zed/releases/download/v$ver/zed-linux-$target.tar.gz"
  hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  json=$(jq --arg s "$sys" --arg t "$target" --arg h "$hash" \
    '.systems[$s] = {target: $t, hash: $h}' <<<"$json")
done

printf '%s\n' "$json" > sources.json
echo "updated to $ver"
