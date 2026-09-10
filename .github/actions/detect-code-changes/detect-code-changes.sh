#!/usr/bin/env bash
#
# Skip code tests only when every changed file is listed as a non-code path.
# Unknown files, unavailable diffs and unsupported events require code tests.
#
# Expected environment variables:
#   PLUGIN_DIR      The path to the plugin directory, relative to the workspace root
#   NON_CODE_PATHS  Newline-separated exact repository-relative paths
#   EVENT_NAME      The GitHub event name
#   BEFORE_SHA      The push's before commit or the pull request's base commit
#   AFTER_SHA       The push's head commit or the pull request's source commit

set -e -o pipefail

CODE=true
if [ "$EVENT_NAME" = "push" ] || [ "$EVENT_NAME" = "pull_request" ]; then
  if [ "$EVENT_NAME" = "pull_request" ]; then
    RANGE="$BEFORE_SHA...$AFTER_SHA"
  else
    RANGE="$BEFORE_SHA..$AFTER_SHA"
  fi
  ZERO=0000000000000000000000000000000000000000
  if [ -n "$BEFORE_SHA" ] && [ -n "$AFTER_SHA" ] && [ "$BEFORE_SHA" != "$ZERO" ]; then
    if CHANGED=$(git -C "$PLUGIN_DIR" diff --no-renames --name-only "$RANGE"); then
      CODE=false
      while IFS= read -r FILE; do
        [ -z "$FILE" ] && continue
        # Match exact paths, not patterns or substrings.
        if ! grep -Fxq -- "$FILE" <<< "$NON_CODE_PATHS"; then
          CODE=true
          break
        fi
      done <<< "$CHANGED"
    fi
  fi
fi
echo "Code changes detected: $CODE"
echo "code-changes=$CODE" >> "$GITHUB_OUTPUT"
