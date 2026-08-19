#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_PRICING_PLAN_REGION:-us-east-1}"

usage() {
  echo "Usage: $0 apply <PLAN_TIER> <DISTRIBUTION_ARN> <WEB_ACL_ARN>" >&2
  echo "       $0 destroy <DISTRIBUTION_ARN>" >&2
  exit 2
}

find_subscription() {
  local distribution_arn="$1"
  aws pricing-plan-manager list-subscriptions \
    --region "${REGION}" \
    --output json |
    jq -c --arg arn "${distribution_arn}" '
      [
        .subscriptionSummaries[]?
        | select(.resourceArns != null)
        | select(.resourceArns | index($arn))
      ]
      | .[0] // empty
    '
}

apply_plan() {
  local plan_tier="$1"
  local distribution_arn="$2"
  local web_acl_arn="$3"
  local existing
  existing="$(find_subscription "${distribution_arn}" || true)"

  if [[ -z "${existing}" ]]; then
    aws pricing-plan-manager create-subscription \
      --region "${REGION}" \
      --plan-family CloudFront \
      --plan-tier "${plan_tier}" \
      --resource-arns "${distribution_arn}" "${web_acl_arn}" \
      --approval-mode IMMEDIATE
    return
  fi

  local current_tier
  current_tier="$(jq -r '.planTier' <<<"${existing}")"
  if [[ "${current_tier}" == "${plan_tier}" ]]; then
    echo "CloudFront pricing plan already ${plan_tier} for ${distribution_arn}"
    return
  fi

  local sub_arn etag
  sub_arn="$(jq -r '.arn' <<<"${existing}")"
  etag="$(jq -r '.eTag' <<<"${existing}")"
  aws pricing-plan-manager update-subscription \
    --region "${REGION}" \
    --arn "${sub_arn}" \
    --plan-tier "${plan_tier}" \
    --if-match "${etag}"
}

destroy_plan() {
  local distribution_arn="$1"
  local existing
  existing="$(find_subscription "${distribution_arn}" || true)"
  if [[ -z "${existing}" ]]; then
    echo "No CloudFront pricing plan subscription for ${distribution_arn}"
    return
  fi

  local sub_arn etag
  sub_arn="$(jq -r '.arn' <<<"${existing}")"
  etag="$(jq -r '.eTag' <<<"${existing}")"
  aws pricing-plan-manager cancel-subscription \
    --region "${REGION}" \
    --arn "${sub_arn}" \
    --if-match "${etag}"
}

command="${1:-}"
case "${command}" in
  apply)
    [[ $# -eq 4 ]] || usage
    apply_plan "$2" "$3" "$4"
    ;;
  destroy)
    [[ $# -eq 2 ]] || usage
    destroy_plan "$2"
    ;;
  *)
    usage
    ;;
esac
