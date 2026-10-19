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

export calls="$temp/herdr-calls"
export existing_workspace=""
herdr() {
    printf '%s\n' "$@" >> "$calls"
    if [[ "$1 $2" == "workspace list" ]]; then
        printf '{"result":{"workspaces":[{"label":"ems","workspace_id":"%s"}]}}\n' \
            "$existing_workspace"
    fi
}
export -f herdr

# Real Git fixtures check detection without contacting a running Herdr server.
normal="$HOME/dev/ems/normal"
mkdir -p "$normal"
git init -q "$normal"
git -C "$normal" -c user.name=Test -c user.email=test@example.invalid \
    -c commit.gpgsign=false commit -qm initial --allow-empty
git -C "$normal" worktree add -qb feature "$HOME/dev/ems/normal-feature"
mkdir -p "$HOME/dev/ems/bare repo"
git clone -q --bare "$normal" "$HOME/dev/ems/bare repo/.bare"
printf 'gitdir: ./.bare\n' > "$HOME/dev/ems/bare repo/.git"
git -C "$HOME/dev/ems/bare repo/.bare" worktree add -q \
    "$HOME/dev/ems/bare repo/feature" feature

assert_open() {
    local target="$1" source="$2" label="$3"
    : > "$calls"
    "$script" --herdr "$target"
    printf '%s\n' worktree open --cwd "$source" --path "$target" \
        --label "$label" --focus > "$temp/expected"
    diff -u "$temp/expected" "$calls"
}
assert_open "$HOME/dev/ems/bare repo/feature" "$(cd "$HOME/dev/ems/bare repo" && pwd -P)" \
    'bare repo-feature'
assert_open "$HOME/dev/ems/normal-feature" "$(cd "$normal" && pwd -P)" normal-feature

# Ordinary repositories and non-Git sandboxes retain workspace creation/reuse.
: > "$calls"
"$script" --herdr "$normal"
printf '%s\n' workspace list workspace create --cwd "$normal" \
    --label normal --focus > "$temp/expected"
diff -u "$temp/expected" "$calls"

export existing_workspace=ws-existing
: > "$calls"
"$script" --herdr "$HOME/sandboxes/ems"
printf '%s\n' workspace list workspace focus ws-existing > "$temp/expected"
diff -u "$temp/expected" "$calls"

# A failed worktree API call must not create an ungrouped workspace as fallback.
herdr() {
    printf '%s\n' "$@" >> "$calls"
    return 17
}
export -f herdr
: > "$calls"
status=0
"$script" --herdr "$HOME/dev/ems/bare repo/feature" || status=$?
[[ "$status" == 17 ]]
[[ "$(head -n1 "$calls")" == worktree ]]
if grep -Fxq workspace "$calls"; then
    echo "FAIL: worktree API failure fell back to plain workspace" >&2
    exit 1
fi
echo "session-worktree Herdr dispatch checks passed"
