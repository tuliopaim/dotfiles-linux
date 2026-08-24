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

- Uses OpenCode's shared background service, so the TUI and web UI use the same sessions. The LaunchAgent (`com.tuliopaim.opencode2-web`) only runs `opencode2 service start` at login. It does not supervise the server because that conflicts with OpenCode's own service manager.
- Port is fixed at 4577. The script stores its password in OpenCode's managed service configuration; the username is ignored, so any value works.
- The service binds to localhost. The Tailscale Serve HTTPS URL works from anywhere inside the tailnet.
- Logs: `/tmp/opencode2-web.log`. Plist: `~/Library/LaunchAgents/com.tuliopaim.opencode2-web.plist`.
- If the phone loads but freezes on an old session, it's browser cache/service worker — have them use a private tab or clear site data for the host.
- QR rendering needs `qrencode` (brew). URLs still print without it.

To change the password or port, edit this script, then run `opencode2-web restart`.
