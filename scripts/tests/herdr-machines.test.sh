#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/herdr-machines"
export HERDR_MACHINE_CATALOG_HOST="$(hostname -s)"

# First select a route, then close after its setup error appears in the picker.
fzf() {
    local args="$*"
    if [[ "$args" == *"setup failed"* ]]; then
        return 130
    fi
    if [[ "$args" != *"--header"* ]]; then
        return 130
    fi
    printf '%s\n' $'-\tOFF\tMac mini · LAN\tmacmini-lan'
}
herdr() {
    [[ "$*" == "machine add macmini-lan --label Mac mini · LAN --remote-session default" ]] \
        || { echo "unexpected command: $*" >&2; return 91; }
    echo "setup failed: connection refused" >&2
    return 1
}
export -f fzf herdr

output=$(bash "$script" </dev/null 2>&1)
[[ "$output" == *"Connecting to Mac mini · LAN"* ]] \
    || { echo "FAIL: no connection progress"; exit 1; }
echo "herdr machine picker checks passed"
