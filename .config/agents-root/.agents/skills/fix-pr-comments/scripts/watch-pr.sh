#!/bin/bash
# watch-pr.sh — Poll a PR for CI failures and unresolved bot review threads.
#
# Usage: ./watch-pr.sh <PR_NUMBER> <OWNER> <REPO> [INTERVAL_SECONDS]
#
# Exits with one of three ACTION lines printed to stdout:
#   ACTION:ALL_CLEAR        — CI passed, no unresolved bot threads
#   ACTION:CI_FAILURE       — one or more checks failed (JSON follows)
#   ACTION:BUGBOT_COMMENTS  — unresolved bot threads found (JSON follows)

set -euo pipefail

PR="${1:?Usage: $0 <PR_NUMBER> <OWNER> <REPO> [INTERVAL_SECONDS]}"
OWNER="${2:?Missing OWNER}"
REPO="${3:?Missing REPO}"
INTERVAL="${4:-60}"
TICK=0

# jq filter written to a temp file so the | inside test() is never seen
# by the shell — avoids "Invalid string" parse errors when the script is
# executed as a single command string.
JQ_FILTER_FILE=$(mktemp /tmp/watch-pr-jq.XXXXXX)
cat > "$JQ_FILTER_FILE" << 'JQEOF'
[
  .data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved == false)
  | select(
      .comments.nodes[0].author.login
      | test("cursor|bugbot|coderabbitai|sourcery|github-actions"; "i")
    )
]
JQEOF

cleanup() {
  rm -f "$JQ_FILTER_FILE"
}
trap cleanup EXIT

while true; do
  TICK=$((TICK + 1))

  # ── CI checks ──────────────────────────────────────────────────────────
  # Exclude Graphite's mergeability check — it is not a real CI check and
  # stays "in_progress" indefinitely on stacked PRs, blocking the loop.
  CI_JSON=$(gh pr checks "$PR" --json name,state 2>/dev/null \
    | jq '[.[] | select(.name | test("Graphite"; "i") | not)]' \
    || echo "[]")
  TOTAL=$(echo "$CI_JSON" | jq 'length')

  FAILING_JSON=$(echo "$CI_JSON" | jq \
    '[.[] | select(.state == "FAILURE" or .state == "TIMED_OUT" or .state == "CANCELLED" or .state == "ACTION_REQUIRED" or .state == "STARTUP_FAILURE")]')
  RUNNING_JSON=$(echo "$CI_JSON" | jq \
    '[.[] | select(.state == "IN_PROGRESS" or .state == "PENDING")]')
  PASSING_JSON=$(echo "$CI_JSON" | jq \
    '[.[] | select(.state == "SUCCESS" or .state == "NEUTRAL" or .state == "SKIPPED")]')

  FAILING=$(echo "$FAILING_JSON" | jq 'length')
  RUNNING=$(echo "$RUNNING_JSON" | jq 'length')
  PASSING=$(echo "$PASSING_JSON" | jq 'length')

  FAILING_NAMES=$(echo "$FAILING_JSON" | jq -r '.[].name' 2>/dev/null \
    | tr '\n' ', ' | sed 's/, $//' || true)
  RUNNING_NAMES=$(echo "$RUNNING_JSON" | jq -r '.[].name' 2>/dev/null \
    | tr '\n' ', ' | sed 's/, $//' || true)

  # ── Unresolved bot threads ─────────────────────────────────────────────
  # Write API response to a temp file so jq reads from a file descriptor,
  # not from an echo'd shell variable — prevents control-character parse errors
  # when comment bodies contain newlines or other special characters.
  GQL_TMP=$(mktemp /tmp/watch-pr-gql.XXXXXX)
  gh api graphql -f query="{ repository(owner: \"$OWNER\", name: \"$REPO\") { pullRequest(number: $PR) { reviewThreads(first: 100) { nodes { id isResolved comments(first: 1) { nodes { author { login } body } } } } } } }" > "$GQL_TMP"
  UNRESOLVED=$(jq -f "$JQ_FILTER_FILE" "$GQL_TMP")
  rm -f "$GQL_TMP"

  UNRESOLVED_COUNT=$(echo "$UNRESOLVED" | jq 'length')

  # ── Status report ──────────────────────────────────────────────────────
  echo "--- [tick $TICK] ---"
  echo "PR comments (unresolved): $UNRESOLVED_COUNT"
  echo "CI total:       $TOTAL"
  echo "CI passing:     $PASSING"
  echo "CI failing:     $FAILING${FAILING_NAMES:+ ($FAILING_NAMES)}"
  echo "CI in-progress: $RUNNING${RUNNING_NAMES:+ ($RUNNING_NAMES)}"

  # ── Exit conditions ────────────────────────────────────────────────────
  if [ "$FAILING" -gt 0 ]; then
    echo "Should stop loop: YES (CI failing)"
    echo "ACTION:CI_FAILURE"
    echo "$FAILING_JSON"
    exit 0
  fi

  if [ "$TOTAL" -gt 0 ] && [ "$RUNNING" -eq 0 ] && [ "$UNRESOLVED_COUNT" -gt 0 ]; then
    echo "Should stop loop: YES (unresolved comments, CI settled)"
    echo "ACTION:BUGBOT_COMMENTS"
    echo "$UNRESOLVED"
    exit 0
  fi

  if [ "$TOTAL" -gt 0 ] && [ "$RUNNING" -eq 0 ] && [ "$FAILING" -eq 0 ] && [ "$UNRESOLVED_COUNT" -eq 0 ]; then
    echo "Should stop loop: YES (all clear)"
    echo "ACTION:ALL_CLEAR"
    exit 0
  fi

  if [ "$TOTAL" -eq 0 ]; then
    echo "Should stop loop: NO (CI not started yet)"
  else
    echo "Should stop loop: NO (waiting for $RUNNING in-progress check(s))"
  fi

  sleep "$INTERVAL"
done
