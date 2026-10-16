#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/session-worktree"
temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT
export HOME="$temp"
export candidates="$temp/candidates"
mkdir -p "$HOME/sandboxes/ems/.dbui/billing-rules-prod" \
    "$HOME/dev/ems/billing-rules/prod" "$HOME/dev/ems/.bare"

# Capture the picker choices, then cancel before creating a workspace.
fzf() {
    tee "$candidates" >/dev/null
    return 130
}
export -f fzf
status=0
"$script" --herdr || status=$?
[[ "$status" == 130 ]]
grep -Fxq "$HOME/sandboxes/ems" "$candidates"
if grep -Fq "$HOME/sandboxes/ems/" "$candidates"; then
    echo "FAIL: nested sandbox folders reached the picker" >&2
    exit 1
fi
grep -Fxq "$HOME/dev/ems/billing-rules/prod" "$candidates"
if grep -Fq '/.bare' "$candidates"; then
    echo "FAIL: bare repository reached the picker" >&2
    exit 1
fi
echo "session-worktree picker checks passed"
