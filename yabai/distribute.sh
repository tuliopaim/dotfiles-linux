#!/usr/bin/env bash
# Move labeled spaces onto their intended display.
#
# Layout:
#   primary  display (built-in / origin): slack, ws6, ws7, ws9
#   external display:                     ws1, ws2, ws3, ws4, ws5, ws8
#
# Single-display hosts (e.g. Mac mini): no-op.

set -euo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ="$(command -v jq || echo /usr/bin/jq)"

PRIMARY_LABELS=(slack ws6 ws7 ws9)
EXTERNAL_LABELS=(ws1 ws2 ws3 ws4 ws5 ws8)

displays_json=$("$YABAI" -m query --displays)
display_count=$(printf '%s' "$displays_json" | "$JQ" 'length')

[ "$display_count" -lt 2 ] && exit 0

# Primary = display at origin (0,0) — that's the one with the macOS menubar.
# Fallback to lowest index if none reports origin.
primary_idx=$(printf '%s' "$displays_json" | "$JQ" -r '
  ([.[] | select(.frame.x == 0 and .frame.y == 0)] | first | .index) //
  ([.[] | .index] | min) | tostring
')

external_idx=$(printf '%s' "$displays_json" | "$JQ" -r --arg p "$primary_idx" '
  [.[] | select(.index != ($p | tonumber)) | .index] | first | tostring
')

move_label() {
  local label="$1"
  local target="$2"
  local current
  current=$("$YABAI" -m query --spaces --space "$label" 2>/dev/null \
    | "$JQ" -r '.display // empty')
  [ -z "$current" ] && return 0
  [ "$current" = "$target" ] && return 0
  "$YABAI" -m space "$label" --display "$target" 2>/dev/null || true
}

for label in "${PRIMARY_LABELS[@]}"; do
  move_label "$label" "$primary_idx"
done

for label in "${EXTERNAL_LABELS[@]}"; do
  move_label "$label" "$external_idx"
done
