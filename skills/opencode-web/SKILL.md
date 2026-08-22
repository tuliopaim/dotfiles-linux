---
name: opencode-web
description: Start, stop, or show access URLs (LAN and Tailscale) for the OpenCode v2 web UI running on this Mac. Use when the user asks to open OpenCode in a browser, access it from their phone, or fix the web UI connection.
---

Manage the OpenCode v2 web UI with the wrapper script:

```sh
opencode2-web            # ensure running + print LAN/Tailscale URLs with QR codes
opencode2-web status     # running? health check
opencode2-web restart    # pick up config changes
opencode2-web stop       # unload service
```

Facts:

- Runs `~/.bun/bin/opencode2 serve` as a LaunchAgent (`com.tuliopaim.opencode2-web`), so it survives reboots and crashes.
- Port is fixed at 4577. Password is set in the script (`OPENCODE_PASSWORD`); username is ignored — any value works.
- LAN URL uses the Mac's Wi-Fi IP; Tailscale URL comes from `tailscale ip -4`. The Tailscale one works from anywhere.
- Logs: `/tmp/opencode2-web.log`. Plist: `~/Library/LaunchAgents/com.tuliopaim.opencode2-web.plist`.
- If the phone loads but freezes on an old session, it's browser cache/service worker — have them use a private tab or clear site data for the host.
- QR rendering needs `qrencode` (brew). URLs still print without it.

To change the password or port, edit this script, then run `opencode2-web restart`.
