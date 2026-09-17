#!/usr/bin/env bash
# Match yabai/distribute.sh: S/6/7/9 on main, 1/2/3/4/5/8 on the first other monitor.
# Run at startup or with ctrl-alt-d. No fixed assignments, so alt-shift-tab works.
set -euo pipefail

AEROSPACE="${AEROSPACE:-/opt/homebrew/bin/aerospace}"

monitors=$("$AEROSPACE" list-monitors --format '%{monitor-id} %{monitor-is-main}')
primary=$(awk '$2 == "true" { print $1; exit }' <<< "$monitors")
external=$(awk '$2 == "false" { print $1; exit }' <<< "$monitors")

# A single display needs no redistribution.
[ -n "$external" ] || exit 0
if [ -z "$primary" ]; then
  echo 'AeroSpace did not report a main monitor.' >&2
  exit 1
fi

for workspace in S 6 7 9; do
  "$AEROSPACE" move-workspace-to-monitor --workspace "$workspace" "$primary"
done

for workspace in 1 2 3 4 5 8; do
  "$AEROSPACE" move-workspace-to-monitor --workspace "$workspace" "$external"
done
