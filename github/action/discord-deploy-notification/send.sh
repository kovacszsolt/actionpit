#!/usr/bin/env bash
set -euo pipefail

MESSAGE="${COMMIT_MESSAGE:-—}"
URL="${COMMIT_URL:-${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}}"

payload=$(jq -n \
  --arg content "$CONTENT_LINE" \
  --arg title "$EMBED_TITLE" \
  --arg repo "$REPO" \
  --arg branch "$BRANCH" \
  --arg actor "$ACTOR" \
  --arg message "$MESSAGE" \
  --arg url "$URL" \
  '{
    content: $content,
    embeds: [
      {
        title: $title,
        fields: [
          { name: "Repository", value: $repo, inline: true },
          { name: "Branch", value: $branch, inline: true },
          { name: "User", value: $actor, inline: true },
          { name: "Commit message", value: $message, inline: false },
          { name: "Commit link", value: $url, inline: false }
        ]
      }
    ]
  }')

# -f: fail on HTTP errors; -s: no progress table; -S: still show errors; -o /dev/null: no response body in log
set +e
curl_msg=$(
  curl -fsS -o /dev/null \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$payload" \
    "$DISCORD_WEBHOOK_URL" 2>&1
)
curl_ec=$?
set -e

if [ "$curl_ec" -ne 0 ]; then
  # Surface curl stderr (e.g. "curl: (22) The requested URL returned error: 401") as the job error line
  echo "::error::${curl_msg:-curl failed with exit code $curl_ec}"
  exit "$curl_ec"
fi
