#!/usr/bin/env bash
# Remove Terragrunt / Terraform local cache artifacts under a path.
#
# Examples:
#   ./clear-terragrunt-cache.sh
#   ./clear-terragrunt-cache.sh --path /path/to/infrastructure
#   ./clear-terragrunt-cache.sh --path . --include-lock-files --dry-run

set -euo pipefail

usage() {
  cat <<EOF
Remove Terragrunt / Terraform local cache artifacts under a path.

Usage:
  $0 [--path PATH] [--include-lock-files] [--dry-run]

Options:
  --path PATH            Root directory to search (default: current working directory)
  --include-lock-files   Also remove .terraform.lock.hcl files
  --dry-run              Print matching paths without deleting them
  -h, --help             Show help

Environment:
  TERRAGRUNT_CLEAR_PATH  Used when --path is not provided

By default this script removes:
  - .terragrunt-cache directories

With --include-lock-files it also removes:
  - .terraform.lock.hcl files
EOF
  exit "${1:-0}"
}

resolve_path() {
  local explicit="$1"
  if [[ -n "$explicit" ]]; then
    echo "$explicit"
    return
  fi
  if [[ -n "${TERRAGRUNT_CLEAR_PATH:-}" ]]; then
    echo "$TERRAGRUNT_CLEAR_PATH"
    return
  fi
  echo "$(pwd)"
}

remove_dirs() {
  local root="$1"
  local dry_run="$2"
  local count=0

  while IFS= read -r -d '' dir; do
    if [[ "$dry_run" == true ]]; then
      printf '[dry-run] %s\n' "$dir"
    else
      rm -rf "$dir"
      printf '%s\n' "$dir"
    fi
    count=$((count + 1))
  done < <(find "$root" -type d -name '.terragrunt-cache' -print0 2>/dev/null || true)

  if [[ "$count" -eq 0 ]]; then
    echo "No .terragrunt-cache directories found." >&2
  elif [[ "$dry_run" == true ]]; then
    echo "Would remove ${count} .terragrunt-cache director(y/ies)." >&2
  else
    echo "Removed ${count} .terragrunt-cache director(y/ies)." >&2
  fi
}

remove_lock_files() {
  local root="$1"
  local dry_run="$2"
  local count=0

  while IFS= read -r -d '' file; do
    if [[ "$dry_run" == true ]]; then
      printf '[dry-run] %s\n' "$file"
    else
      rm -f "$file"
      printf '%s\n' "$file"
    fi
    count=$((count + 1))
  done < <(find "$root" -type f -name '.terraform.lock.hcl' -print0 2>/dev/null || true)

  if [[ "$count" -eq 0 ]]; then
    echo "No .terraform.lock.hcl files found." >&2
  elif [[ "$dry_run" == true ]]; then
    echo "Would remove ${count} .terraform.lock.hcl file(s)." >&2
  else
    echo "Removed ${count} .terraform.lock.hcl file(s)." >&2
  fi
}

main() {
  local path=""
  local include_lock_files=false
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help|help)
        usage
        ;;
      --path|--root)
        shift
        path="${1:?--path requires a value}"
        ;;
      --include-lock-files)
        include_lock_files=true
        ;;
      --dry-run)
        dry_run=true
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage 1
        ;;
    esac
    shift
  done

  path="$(resolve_path "$path")"
  if [[ ! -d "$path" ]]; then
    echo "Path does not exist or is not a directory: ${path}" >&2
    exit 1
  fi
  path="$(cd "$path" && pwd)"

  echo "Path:               ${path}" >&2
  echo "Include lock files: ${include_lock_files}" >&2
  if [[ "$dry_run" == true ]]; then
    echo "Mode:               dry-run" >&2
  fi

  remove_dirs "$path" "$dry_run"
  if [[ "$include_lock_files" == true ]]; then
    remove_lock_files "$path" "$dry_run"
  fi
}

main "$@"
