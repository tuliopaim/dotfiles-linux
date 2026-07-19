---
name: ssh-machines
description: Run commands or perform work on Tulio's named machines over SSH. Use when a request references macbook, macmini, homelab, or asks an agent to do something on another machine.
---

# SSH Machines

Use SSH host aliases; do not hard-code addresses:

- `macbook` — current MacBook on LAN
- `macmini` — Mac mini on LAN
- `homelab` — Linux homelab on LAN
- `<name>-ts` — same machine over Tailscale when away from the home LAN

## Workflow

1. Confirm the target with `ssh <name> 'hostname'`.
2. Run non-interactive commands with `ssh <name> '<command>'`.
3. For file transfer, use `scp` or stream through SSH.
4. Report which host changed and the verification result.

Prefer LAN aliases. If unreachable, retry once with `<name>-ts`. Quote remote commands so local shell expansion cannot alter them.

The three computers intentionally share `~/.ssh/homelab`. Never copy this private key elsewhere, print it, or put it in a prompt/log. The phone must remain password-only: never disable SSH password authentication or modify `sshd` authentication settings unless explicitly asked.

Shared aliases live in `~/.ssh/machines.conf`. Keep that file identical on macbook, macmini, and homelab when machine addresses change. Preserve each machine's main `~/.ssh/config`; it contains machine-specific entries.
