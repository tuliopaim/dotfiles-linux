#!/usr/bin/env sh
# Claude Code status line.
#
# Mirrors the zsh `amuse` prompt (bold green directory, magenta  branch) plus
# the cyan hostname from RPROMPT, then a context-window usage bar.
#
# Wired up per machine in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
#
# Claude Code pipes session JSON on stdin; see
# https://code.claude.com/docs/en/statusline for the full field list.

input=$(cat)

# A real ESC byte. printf only expands \033 inside the *format string*, never
# inside %s arguments, so building the line from escape-bearing variables and
# emitting it with '%s\n' is the only arrangement that can't silently break.
esc=$(printf '\033')

# One jq pass for everything, since this runs on every render tick. `tokens` is
# what currently occupies the context window (input + cache reads + writes) --
# as of v2.1.132 it is NOT a cumulative session total.
IFS='	' read -r dir pct tokens window <<EOF
$(printf '%s' "$input" | jq -r '
    def si: if . >= 1000000 then "\((. / 1000000) | floor)M"
            elif . >= 10000 then "\((. / 1000) | floor)k"
            elif . >= 1000 then "\((. / 100 | floor) / 10)k"
            else "\(.)" end;
    [ .workspace.current_dir,
      (.context_window.used_percentage // 0),
      (.context_window.total_input_tokens // 0 | si),
      (.context_window.context_window_size // 200000 | si)
    ] | @tsv')
EOF

dir=$(basename "$dir")
branch=$(git --no-optional-locks branch --show-current 2>/dev/null)
host=$(hostname -s)

# used_percentage is null before the first API response and again after
# /compact, hence the `// 0` above.
pct=$(printf '%.0f' "$pct")
[ "$pct" -gt 100 ] && pct=100
[ "$pct" -lt 0 ] && pct=0

width=20
filled=$((pct * width / 100))
bar=""
i=0
while [ "$i" -lt "$width" ]; do
    # Braces are load-bearing: some shells (bash 5.x) accept the leading 0xE2
    # byte of these block glyphs as an identifier char, so an unbraced "$bar█"
    # parses as ${bar<0xE2>} -- unset -- and leaves two stray bytes behind.
    if [ "$i" -lt "$filled" ]; then
        bar="${bar}█"
    else
        bar="${bar}░"
    fi
    i=$((i + 1))
done

if [ "$pct" -ge 90 ]; then
    color="$esc[31m"
elif [ "$pct" -ge 70 ]; then
    color="$esc[33m"
else
    color="$esc[32m"
fi

git_segment=""
[ -n "$branch" ] && git_segment=" $esc[35m ${branch}$esc[0m"

printf '%s\n' "$esc[1;32m$dir$esc[0m$git_segment $esc[36m$host$esc[0m $color[$bar] $pct%$esc[0m $esc[90m$tokens/$window$esc[0m"
