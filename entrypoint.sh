#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

REPO_PRIVATE=$(jq -r '.repository.private | tostring' "${GITHUB_EVENT_PATH:-}" 2>/dev/null || echo "")
UPSTREAM="planetscale/ghcommit-action"
ACTION_REPO="${GITHUB_ACTION_REPOSITORY:-}"
DOCS_URL="https://docs.stepsecurity.io/actions/stepsecurity-maintained-actions"

echo ""
echo -e "\033[1;36mStepSecurity Maintained Action\033[0m"
echo "Secure drop-in replacement for $UPSTREAM"
if [ "$REPO_PRIVATE" = "false" ]; then
  echo -e "\033[32m✓ Free for public repositories\033[0m"
fi
echo -e "\033[36mLearn more:\033[0m $DOCS_URL"
echo ""

if [ "$REPO_PRIVATE" != "false" ]; then
  SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"

  if [ "$SERVER_URL" != "https://github.com" ]; then
    BODY=$(printf '{"action":"%s","ghes_server":"%s"}' "$ACTION_REPO" "$SERVER_URL")
  else
    BODY=$(printf '{"action":"%s"}' "$ACTION_REPO")
  fi

  API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/maintained-actions-subscription"

  RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "$API_URL" -o /dev/null) && CURL_EXIT_CODE=0 || CURL_EXIT_CODE=$?

  if [ "$CURL_EXIT_CODE" -ne 0 ]; then
    echo "Timeout or API not reachable. Continuing to next step."
  elif [ "$RESPONSE" = "403" ]; then
    echo -e "::error::\033[1;31mThis action requires a StepSecurity subscription for private repositories.\033[0m"
    echo -e "::error::\033[31mLearn how to enable a subscription: $DOCS_URL\033[0m"
    exit 1
  fi
fi

COMMIT_MESSAGE="${1:?Missing commit_message input}"
REPO="${2:?Missing repo input}"
BRANCH="${3:?Missing branch input}"
EMPTY="${4:-false}"
read -r -a FILE_PATTERNS <<<"${5:?Missing file_pattern input}"

git config --global --add safe.directory "$GITHUB_WORKSPACE"

adds=()
deletes=()

while IFS= read -r -d $'\0' line; do
  [[ -n "${DEBUG:-}" ]] && echo "line: '$line'"

  # Extract the status in the tree and status in the index (first two characters)
  index_status="${line:0:1}"
  tree_status="${line:1:1}"

  # Renamed files have status code 'R' and two filenames separated by NUL. We need to read
  # an additional chunk (up to the next NUL) to get the new filename.
  if [[ "$index_status" == "R" || "$tree_status" == "R" ]]; then
    IFS= read -r -d $'\0' old_filename
    new_filename="${line:3}"

    echo "Renamed file detected:"
    echo "Old Filename: $old_filename"
    echo "New Filename: $new_filename"
    echo "-----------------------------"
    adds+=("$new_filename")
    deletes+=("$old_filename")
    continue
  fi

  # Extract the filename by removing the first three characters (two statuses and a whitespace)
  filename="${line:3}"
  echo "Filename: $filename"

  # Print the parsed information, useful for debugging
  echo "Index Status: $index_status"
  echo "Tree Status: $tree_status"
  echo "Filename: $filename"
  echo "-----------------------------"
  # https://git-scm.com/docs/git-status

  # handle adds (A), modifications (M), and type changes (T):
  [[ "$tree_status" =~ A|M|T || "$index_status" =~ A|M|T ]] && adds+=("$filename")

  # handle untracked files (??):
  # https://github.com/planetscale/ghcommit-action/issues/43#issuecomment-1950986790
  [[ "$tree_status" == "?" && "$index_status" == "?" ]] && adds+=("$filename")

  # handle deletes (D):
  [[ "$tree_status" =~ D || "$index_status" =~ D ]] && deletes+=("$filename")

done < <(git status -s --porcelain=v1 -z -- "${FILE_PATTERNS[@]}")

if [[ "${#adds[@]}" -eq 0 && "${#deletes[@]}" -eq 0 && "$EMPTY" == "false" ]]; then
  echo "No changes detected, exiting"
  exit 0
fi

ghcommit_args=()
ghcommit_args+=(-b "$BRANCH")
ghcommit_args+=(-r "$REPO")
ghcommit_args+=(-m "$COMMIT_MESSAGE")

if [[ "$EMPTY" =~ ^(true|1|yes)$ ]]; then
  ghcommit_args+=(--empty)
fi

ghcommit_args+=("${adds[@]/#/--add=}")
ghcommit_args+=("${deletes[@]/#/--delete=}")

[[ -n "${DEBUG:-}" ]] && echo "ghcommit args: '${ghcommit_args[*]}'"

output=$(ghcommit "${ghcommit_args[@]}" 2>&1) || {
  # Show the output on error. This is needed since the exit immediately flag is set.
  echo "$output" 1>&2;
  exit 1
}
echo "$output"

commit_url=$(echo "$output" | grep "Success. New commit:" | awk '{print $NF}')
commit_hash=$(echo "$commit_url" | awk -F '/' '{print $NF}')
echo "commit-url=$commit_url" >> "$GITHUB_OUTPUT"
echo "commit-hash=$commit_hash" >> "$GITHUB_OUTPUT"
