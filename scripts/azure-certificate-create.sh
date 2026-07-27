#!/usr/bin/env bash
# Create a managed certificate for an Azure Container Apps environment.
# Requirements: Azure CLI installed and authenticated.
#
# Examples:
#   ./azure-certificate-create.sh \
#     --resource-group "<RESOURCE_GROUP>" \
#     --environment "<CONTAINER_APP_ENVIRONMENT>" \
#     --hostname "app.example.com"
#
#   ./azure-certificate-create.sh \
#     --resource-group "<RESOURCE_GROUP>" \
#     --environment "<CONTAINER_APP_ENVIRONMENT>" \
#     --hostname "app.example.com" \
#     --validation-method TXT \
#     --subscription "<SUBSCRIPTION_ID>"

set -euo pipefail

DEFAULT_VALIDATION_METHOD="CNAME"

usage() {
  cat <<EOF
Create a managed certificate for an Azure Container Apps environment.

Usage:
  $0 --resource-group RESOURCE_GROUP --environment ENVIRONMENT --hostname HOSTNAME [options]

Required:
  --resource-group NAME      Azure resource group name
  --environment NAME         Container Apps environment name
  --hostname HOSTNAME        Custom domain / hostname for the certificate

Options:
  --validation-method VALUE  Domain validation method (default: ${DEFAULT_VALIDATION_METHOD})
  --subscription ID          Azure subscription ID or name
  --dry-run                  Print the command without executing it
  -h, --help                Show help

Environment:
  AZURE_RESOURCE_GROUP       Used when --resource-group is not provided
  CONTAINER_APP_ENVIRONMENT  Used when --environment is not provided
  CERT_HOSTNAME              Used when --hostname is not provided
  AZURE_SUBSCRIPTION_ID      Used when --subscription is not provided

Command:
  az containerapp env certificate create
EOF
  exit "${1:-0}"
}

require_az() {
  command -v az >/dev/null 2>&1 || {
    echo "Azure CLI (az) is required." >&2
    exit 1
  }
}

resolve_value() {
  local explicit="$1"
  local env_name="$2"
  if [[ -n "$explicit" ]]; then
    echo "$explicit"
    return
  fi
  if [[ -n "${!env_name:-}" ]]; then
    echo "${!env_name}"
  fi
}

print_summary() {
  local resource_group="$1"
  local environment="$2"
  local hostname="$3"
  local validation_method="$4"
  local subscription="$5"

  cat <<EOF

Done.

Resource group:     ${resource_group}
Environment:        ${environment}
Hostname:           ${hostname}
Validation method:  ${validation_method}
Subscription:       ${subscription:-<current Azure CLI context>}
EOF
}

main() {
  local resource_group=""
  local environment=""
  local hostname=""
  local validation_method="${DEFAULT_VALIDATION_METHOD}"
  local subscription=""
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help|help)
        usage
        ;;
      --resource-group)
        shift
        resource_group="${1:?--resource-group requires a value}"
        ;;
      --environment|--env)
        shift
        environment="${1:?--environment requires a value}"
        ;;
      --hostname|--domain)
        shift
        hostname="${1:?--hostname requires a value}"
        ;;
      --validation-method)
        shift
        validation_method="${1:?--validation-method requires a value}"
        ;;
      --subscription)
        shift
        subscription="${1:?--subscription requires a value}"
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

  require_az

  resource_group="$(resolve_value "$resource_group" "AZURE_RESOURCE_GROUP")"
  environment="$(resolve_value "$environment" "CONTAINER_APP_ENVIRONMENT")"
  hostname="$(resolve_value "$hostname" "CERT_HOSTNAME")"
  subscription="$(resolve_value "$subscription" "AZURE_SUBSCRIPTION_ID")"

  if [[ -z "${resource_group// /}" ]]; then
    echo "Resource group is required. Use --resource-group or AZURE_RESOURCE_GROUP." >&2
    exit 1
  fi
  if [[ -z "${environment// /}" ]]; then
    echo "Container Apps environment is required. Use --environment or CONTAINER_APP_ENVIRONMENT." >&2
    exit 1
  fi
  if [[ -z "${hostname// /}" ]]; then
    echo "Hostname is required. Use --hostname or CERT_HOSTNAME." >&2
    exit 1
  fi

  local cmd=(
    az containerapp env certificate create
    --resource-group "$resource_group"
    --name "$environment"
    --hostname "$hostname"
    --validation-method "$validation_method"
  )
  if [[ -n "$subscription" ]]; then
    cmd+=(--subscription "$subscription")
  fi

  echo "Resource group:     ${resource_group}" >&2
  echo "Environment:        ${environment}" >&2
  echo "Hostname:           ${hostname}" >&2
  echo "Validation method:  ${validation_method}" >&2
  if [[ -n "$subscription" ]]; then
    echo "Subscription:       ${subscription}" >&2
  fi

  if [[ "$dry_run" == true ]]; then
    printf '[dry-run] '
    printf '%q ' "${cmd[@]}"
    printf '\n'
    exit 0
  fi

  "${cmd[@]}"
  print_summary "$resource_group" "$environment" "$hostname" "$validation_method" "$subscription"
}

main "$@"
