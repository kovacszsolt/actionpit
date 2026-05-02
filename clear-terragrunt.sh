#!/usr/bin/env bash
# Remove all .terragrunt-cache directories and .terraform.lock.hcl files under this repository.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

count_cache=0
while IFS= read -r -d '' dir; do
  rm -rf "$dir"
  printf '%s\n' "$dir"
  count_cache=$((count_cache + 1))
done < <(find "$ROOT" -type d -name '.terragrunt-cache' -print0 2>/dev/null || true)

if [ "$count_cache" -eq 0 ]; then
  echo "No .terragrunt-cache directories found."
else
  echo "Removed ${count_cache} .terragrunt-cache director(y/ies)."
fi

count_lock=0
while IFS= read -r -d '' f; do
  rm -f "$f"
  printf '%s\n' "$f"
  count_lock=$((count_lock + 1))
done < <(find "$ROOT" -type f -name '.terraform.lock.hcl' -print0 2>/dev/null || true)

if [ "$count_lock" -eq 0 ]; then
  echo "No .terraform.lock.hcl files found."
else
  echo "Removed ${count_lock} .terraform.lock.hcl file(s)."
fi
