#!/usr/bin/env bash
set -euo pipefail

zshrc="$(cd "$(dirname "$0")/../../zsh" && pwd)/.zshrc"
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

# A bare HOME skips unrelated shell plugins while sourcing the real entry point.
for scenario in ghostty-stale herdr ghostty-clean other-terminal; do
    terminal=ghostty
    marker=1
    case "$scenario" in
        herdr) terminal=herdr ;;
        ghostty-clean) marker= ;;
        other-terminal) terminal=Apple_Terminal ;;
    esac
    env HOME="$test_home" ZSHRC_UNDER_TEST="$zshrc" SCENARIO="$scenario" \
        TERM_PROGRAM="$terminal" HERDR_ENV="$marker" \
        HERDR_PANE_ID=stale-pane HERDR_TAB_ID=stale-tab \
        HERDR_WORKSPACE_ID=stale-workspace HERDR_SOCKET_PATH=stale-socket \
        HERDR_CLIENT_SOCKET_PATH=stale-client HERDR_BIN_PATH=stale-bin \
        HERDR_SESSION=selected-session HERDR_CONFIG_PATH=custom-config \
        HERDR_LOG=warn SSH_AUTH_SOCK=working-agent \
        zsh -f -c '
            source "$ZSHRC_UNDER_TEST"
            for variable in HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID \
                HERDR_WORKSPACE_ID HERDR_SOCKET_PATH HERDR_CLIENT_SOCKET_PATH \
                HERDR_BIN_PATH HERDR_SESSION; do
                if [[ "$SCENARIO" == ghostty-stale ]]; then
                    (( ! ${+parameters[$variable]} )) || {
                        print -u2 "FAIL: $SCENARIO retained $variable"
                        exit 1
                    }
                else
                    (( ${+parameters[$variable]} )) || exit 1
                fi
            done
            [[ "$HERDR_CONFIG_PATH" == custom-config && "$HERDR_LOG" == warn &&
                "$SSH_AUTH_SOCK" == working-agent &&
                "$TERM_PROGRAM" != "" ]] || exit 1
            [[ "$SCENARIO" == ghostty-stale || "$HERDR_PANE_ID" == stale-pane &&
                "$HERDR_SESSION" == selected-session ]] || exit 1
        '
done
echo "Ghostty/Herdr environment checks passed"
