#!/usr/bin/env bash
# Persist yabai space labels across restarts and display events.
# Mapping is keyed by macOS space UUID, which is stable for the
# lifetime of the space (survives yabai restarts and most display
# disconnects). Storage: ~/.cache/yabai-labels.json
#
# Usage: labels.sh save | restore

set -euo pipefail

# Signals run with a minimal PATH, so we resolve binaries explicitly.
# /usr/bin/jq is bundled in macOS Sonoma+; fall back to PATH if missing.
YABAI=/opt/homebrew/bin/yabai
JQ="$(command -v jq || echo /usr/bin/jq)"
DB="${HOME}/.cache/yabai-labels.json"

mkdir -p "$(dirname "$DB")"

case "${1:-}" in
  save)
    "$YABAI" -m query --spaces \
      | "$JQ" '[.[] | select(.label != "") | {key: .uuid, value: .label}] | from_entries' \
      > "${DB}.tmp"
    mv "${DB}.tmp" "$DB"
    ;;

  restore)
    [ -f "$DB" ] || exit 0
    "$YABAI" -m query --spaces \
      | "$JQ" -r --slurpfile db "$DB" '
          .[] as $s
          | ($db[0][$s.uuid] // empty) as $label
          | select($label) | "\($s.index)\t\($label)"
        ' \
      | while IFS=$'\t' read -r idx label; do
          "$YABAI" -m space "$idx" --label "$label" 2>/dev/null || true
        done
    ;;

  *)
    echo "usage: $0 save|restore" >&2
    exit 2
    ;;
esac
