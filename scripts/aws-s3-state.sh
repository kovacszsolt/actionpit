#!/usr/bin/env bash
# Create an S3 bucket for Terraform / Terragrunt remote state.
# Requirements: AWS CLI configured and authenticated.
#
# Default generated name:
#   terraform-state-<ACCOUNT_ID>-<REGION>
# or
#   terraform-state-<ACCOUNT_ID>-<REGION>-<SUFFIX>
#
# Examples:
#   ./aws-s3-state.sh
#   ./aws-s3-state.sh --region eu-north-1 --suffix shared
#   AWS_REGION=<REGION> ./aws-s3-state.sh --bucket terraform-state-123456789012-<REGION>

set -euo pipefail

usage() {
  cat <<EOF
Create an S3 bucket for Terraform / Terragrunt remote state.

Usage:
  $0 [--region REGION] [--suffix SUFFIX] [--bucket BUCKET_NAME] [--dry-run]

Options:
  --region REGION     AWS region (fallback: AWS_REGION or AWS CLI default region)
  --suffix SUFFIX     Optional bucket name suffix
  --bucket NAME       Full bucket name (overrides generated name)
  --dry-run           Print actions without creating anything
  -h, --help          Show help

Environment:
  AWS_REGION          Used when --region is not provided

Bucket settings:
  - account-regional namespace (when the name matches terraform-state-<ACCOUNT_ID>-<REGION>[-SUFFIX])
  - versioning: Enabled
  - encryption: AES256 (SSE-S3)
  - public access: blocked
  - object ownership: BucketOwnerEnforced

Example root.hcl:
  bucket = "terraform-state-<ACCOUNT_ID>-<REGION>-<SUFFIX>"
  region = "<REGION>"
  encrypt = true
  use_lockfile = true
EOF
  exit "${1:-0}"
}

require_aws() {
  command -v aws >/dev/null 2>&1 || {
    echo "AWS CLI (aws) is required." >&2
    exit 1
  }
}

resolve_region() {
  local region="${1:-}"
  if [[ -n "$region" ]]; then
    echo "$region"
    return
  fi
  if [[ -n "${AWS_REGION:-}" ]]; then
    echo "$AWS_REGION"
    return
  fi
  region="$(aws configure get region 2>/dev/null || true)"
  if [[ -n "$region" ]]; then
    echo "$region"
    return
  fi
  echo "Region is required. Use --region, AWS_REGION, or configure a default AWS CLI region." >&2
  exit 1
}

resolve_account_id() {
  aws sts get-caller-identity --query Account --output text
}

resolve_bucket_name() {
  local explicit="$1"
  local account_id="$2"
  local region="$3"
  local suffix="$4"

  if [[ -n "$explicit" ]]; then
    echo "$explicit"
    return
  fi

  if [[ -n "$suffix" ]]; then
    echo "terraform-state-${account_id}-${region}-${suffix}"
    return
  fi

  echo "terraform-state-${account_id}-${region}"
}

bucket_exists() {
  local bucket="$1"
  aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1
}

uses_account_regional_namespace() {
  local bucket="$1"
  local account_id="$2"
  local region="$3"

  [[ "$bucket" =~ ^terraform-state-${account_id}-${region}(-[a-z0-9.-]+)?$ ]]
}

create_bucket() {
  local bucket="$1"
  local region="$2"
  local account_id="$3"

  if bucket_exists "$bucket"; then
    echo "Bucket already exists: ${bucket}" >&2
    return 0
  fi

  local namespace_args=()
  if uses_account_regional_namespace "$bucket" "$account_id" "$region"; then
    namespace_args=(--bucket-namespace account-regional)
    echo "Using account-regional bucket namespace." >&2
  fi

  echo "Creating bucket: ${bucket} (${region})" >&2
  if [[ "$region" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "$bucket" \
      --region "$region" \
      "${namespace_args[@]}"
  else
    aws s3api create-bucket \
      --bucket "$bucket" \
      --region "$region" \
      --create-bucket-configuration "LocationConstraint=${region}" \
      "${namespace_args[@]}"
  fi
}

configure_bucket() {
  local bucket="$1"

  echo "Enabling versioning..." >&2
  aws s3api put-bucket-versioning \
    --bucket "$bucket" \
    --versioning-configuration Status=Enabled

  echo "Configuring encryption (AES256)..." >&2
  aws s3api put-bucket-encryption \
    --bucket "$bucket" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" },
        "BucketKeyEnabled": true
      }]
    }'

  echo "Configuring public access block..." >&2
  aws s3api put-public-access-block \
    --bucket "$bucket" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  echo "Configuring object ownership: BucketOwnerEnforced..." >&2
  aws s3api put-bucket-ownership-controls \
    --bucket "$bucket" \
    --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'
}

print_summary() {
  local bucket="$1"
  local region="$2"
  local account_id="$3"

  cat <<EOF

Done.

Bucket:  ${bucket}
Region:  ${region}
Account: ${account_id}

root.hcl:

  locals {
    remote_state_config = {
      bucket = "${bucket}"
      region = "${region}"
    }
  }

Terragrunt state key after init:
  \${path_relative_to_include()}/terraform.tfstate
EOF
}

main() {
  local region=""
  local suffix=""
  local bucket=""
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help|help)
        usage
        ;;
      --region)
        shift
        region="${1:?--region requires a value}"
        ;;
      --suffix)
        shift
        suffix="${1:?--suffix requires a value}"
        ;;
      --bucket)
        shift
        bucket="${1:?--bucket requires a value}"
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

  require_aws

  region="$(resolve_region "$region")"
  local account_id
  account_id="$(resolve_account_id)"
  bucket="$(resolve_bucket_name "$bucket" "$account_id" "$region" "$suffix")"

  echo "Account: ${account_id}" >&2
  echo "Region:  ${region}" >&2
  echo "Bucket:  ${bucket}" >&2

  if [[ "$dry_run" == true ]]; then
    echo "[dry-run] create-bucket + versioning + encryption + public access block + ownership controls" >&2
    exit 0
  fi

  create_bucket "$bucket" "$region" "$account_id"
  configure_bucket "$bucket"
  print_summary "$bucket" "$region" "$account_id"
}

main "$@"
