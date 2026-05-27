#!/usr/bin/env bash
# Persist & repair yabai space labels.
#
# Storage: ~/.cache/yabai-labels.json (uuid -> label map)
#
# Subcommands:
#   save     — snapshot current label state to disk
#   restore  — UUID-based restore, then `ensure`
#   ensure   — fill any missing canonical labels (ws1..ws9, slack) into
#              spaces that have no label. Order-independent, idempotent,
#              survives display reshuffles that change space indexes.
#   cleanup  — destroy unlabeled orphan spaces, leaving only labeled ones
#              (macOS keeps a minimum of 1 space per display).

set -euo pipefail

# Signals run with a minimal PATH, so we resolve binaries explicitly.
YABAI=/opt/homebrew/bin/yabai
JQ="$(command -v jq || echo /usr/bin/jq)"
DB="${HOME}/.cache/yabai-labels.json"

CANONICAL_LABELS=(ws1 ws2 ws3 ws4 ws5 ws6 ws7 ws8 ws9 slack)

mkdir -p "$(dirname "$DB")"

ensure_labels() {
  local applied
  applied=$("$YABAI" -m query --spaces | "$JQ" -r '.[].label | select(. != "")')

  local missing=()
  for label in "${CANONICAL_LABELS[@]}"; do
    if ! printf '%s\n' "$applied" | grep -qx "$label"; then
      missing+=("$label")
    fi
  done

  [ ${#missing[@]} -eq 0 ] && return 0

  local unlabeled
  unlabeled=$("$YABAI" -m query --spaces | "$JQ" -r '.[] | select(.label == "") | .index')

  local i=0
  while IFS= read -r idx; do
    [ -z "$idx" ] && continue
    [ $i -ge ${#missing[@]} ] && break
    "$YABAI" -m space "$idx" --label "${missing[$i]}" 2>/dev/null || true
    i=$((i+1))
  done <<< "$unlabeled"
}

cleanup_orphans() {
  while true; do
    local idx
    idx=$("$YABAI" -m query --spaces \
      | "$JQ" -r '[.[] | select(.label == "")] | first | .index // empty')
    [ -z "$idx" ] && break
    "$YABAI" -m space "$idx" --destroy 2>/dev/null || break
  done
}

case "${1:-}" in
  save)
    "$YABAI" -m query --spaces \
      | "$JQ" '[.[] | select(.label != "") | {key: .uuid, value: .label}] | from_entries' \
      > "${DB}.tmp"
    mv "${DB}.tmp" "$DB"
    ;;

  restore)
    if [ -f "$DB" ]; then
      "$YABAI" -m query --spaces \
        | "$JQ" -r --slurpfile db "$DB" '
            .[] as $s
            | ($db[0][$s.uuid] // empty) as $label
            | select($label) | "\($s.index)\t\($label)"
          ' \
        | while IFS=$'\t' read -r idx label; do
            "$YABAI" -m space "$idx" --label "$label" 2>/dev/null || true
          done
    fi
    ensure_labels
    ;;

  ensure)
    ensure_labels
    ;;

  cleanup)
    cleanup_orphans
    ;;

  *)
    echo "usage: $0 save|restore|ensure|cleanup" >&2
    exit 2
    ;;
esac
