# Ghostty launched from a Herdr pane inherits stale pane context.
# Real Herdr panes set TERM_PROGRAM=herdr and must keep their context.
if [[ "$TERM_PROGRAM" == "ghostty" && "${HERDR_ENV:-}" == "1" ]]; then
    unset HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID \
        HERDR_SOCKET_PATH HERDR_CLIENT_SOCKET_PATH HERDR_BIN_PATH HERDR_SESSION
fi

# Source shared configuration
if [[ -r "$HOME/dotfiles/zsh/.zshrc.shared" ]]; then
    source "$HOME/dotfiles/zsh/.zshrc.shared"
fi

# Platform-specific config
if [[ "$(uname)" == "Darwin" ]]; then
    [[ -r "$HOME/dotfiles/zsh/.zshrc.macos" ]] && source "$HOME/dotfiles/zsh/.zshrc.macos"
else
    [[ -r "$HOME/dotfiles/zsh/.zshrc.linux" ]] && source "$HOME/dotfiles/zsh/.zshrc.linux"
fi
