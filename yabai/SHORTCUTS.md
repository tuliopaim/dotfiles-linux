# yabai + skhd — Keyboard Shortcuts

## Window Navigation (Vim-style)

| Keys | Action |
|------|--------|
| `alt` + `h` | Focus window **left** (or **stack previous**) |
| `alt` + `j` | Focus window **down** |
| `alt` + `k` | Focus window **up** |
| `alt` + `l` | Focus window **right** (or **stack next**) |

## Move Windows

| Keys | Action |
|------|--------|
| `alt` + `shift` + `h` | Move window **left** (warp) |
| `alt` + `shift` + `j` | Move window **down** (warp) |
| `alt` + `shift` + `k` | Move window **up** (warp) |
| `alt` + `shift` + `l` | Move window **right** (warp) |

## Resize

| Keys | Action |
|------|--------|
| `alt` + `shift` + `-` | Resize **shrink** |
| `alt` + `shift` + `=` | Resize **grow** |

## Workspace Switching

| Keys | Workspace |
|------|-----------|
| `alt` + `1` … `9` | Switch to workspace **1–9** |
| `alt` + `0` | Switch to **Slack** (workspace 10) |
| `alt` + `s` | Switch to **Slack** (workspace 10) |
| `alt` + `tab` | Toggle **previous workspace** |

## Move Window to Workspace + Follow

| Keys | Action |
|------|--------|
| `alt` + `shift` + `1` … `9` | Move window to workspace **1–9** and follow |
| `alt` + `shift` + `0` | Move window to **Slack** and follow |
| `alt` + `shift` + `s` | Move window to **Slack** and follow |

## Display / Monitor

| Keys | Action |
|------|--------|
| `alt` + `shift` + `tab` | Move focus to **next display** |

## Fullscreen & Minimize

| Keys | Action |
|------|--------|
| `alt` + `f` | Toggle **yabai fullscreen** (zoom) |
| `alt` + `shift` + `f` | Toggle **macOS native fullscreen** |
| `alt` + `m` | **Minimize** window |

## Layouts

| Keys | Action |
|------|--------|
| `alt` + `/` | Set layout to **BSP** (tiles) |
| `alt` + `.` | Set layout to **Stack** |
| `alt` + `shift` + `.` | Set layout to **Float** |

## Launch

| Keys | Action |
|------|--------|
| `alt` + `return` | Open **Ghostty** terminal |

---

## Service Mode (`ctrl` + `alt` prefix)

| Keys | Action |
|------|--------|
| `ctrl` + `alt` + `r` | **Reset layout** — flatten workspace tree + balance |
| `ctrl` + `alt` + `f` | Toggle space layout to **Float** |
| `ctrl` + `alt` + `b` | Return space layout to **BSP** |
| `ctrl` + `alt` + `backspace` | **Close** focused window |
| `ctrl` + `alt` + `h` | **Insert** window to the left |
| `ctrl` + `alt` + `j` | **Insert** window below |
| `ctrl` + `alt` + `k` | **Insert** window above |
| `ctrl` + `alt` + `l` | **Insert** window to the right |
| `ctrl` + `alt` + `.` | **Reload skhd only** (preserves yabai labels) |
| `ctrl` + `alt` + `shift` + `.` | **Full restart** — yabai + skhd (use when yabairc changed) |
| `ctrl` + `alt` + `a` | **Reload scripting addition** (fix when space→display moves fail) |

---

## Auto-Floating Windows

These apps open as floating (outside the tiling grid):
- **Shottr** (screenshot tool)
- **System Settings**
- **Calculator**
- **Dictionary**
- **QuickTime Player**
- Any window titled "Preferences" or "Settings"
