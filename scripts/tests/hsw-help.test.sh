#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/hsw"

# Help and invalid arguments must never reach Herdr, even inside a live pane.
herdr() {
    echo "FAIL: invoked Herdr: $*" >&2
    return 90
}
export -f herdr
export HERDR_PANE_ID=caller-pane

output=$(bash "$script" --help)
[[ "$output" == Usage:* ]]
output=$(bash "$script" -h)
[[ "$output" == Usage:* ]]
if output=$(bash "$script" --invalid 2>&1); then
    echo "FAIL: accepted an invalid argument" >&2
    exit 1
fi
[[ "$output" == "hsw: unexpected argument: --invalid" ]]
echo "hsw help checks passed"
