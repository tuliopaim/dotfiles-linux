# Switch from yabai to AeroSpace

Use the official AeroSpace package and stop both yabai and skhd. AeroSpace handles
its own shortcuts, including Ghostty and dictation.

The config targets the official Homebrew release `0.21.3-Beta`, checked on
September 16, 2026. It uses config version 2, explicit persistent workspaces, and
the current `on-window-detected` syntax. Desktop behavior on macOS 27 still needs
the hands-on checks below.

## What matches the yabai setup

- Six-pixel gaps and mouse following keyboard focus.
- Option+1 through 9 selects a workspace. Option+0 and Option+S select `S`, the
  Slack workspace. Add Shift to move the focused window there and follow it.
- Option+Return opens Ghostty. F9 and Command+Shift+Option+Space run the existing
  dictation and cancel commands.
- Option+H/J/K/L focuses windows; adding Shift moves them.
- Option+F maximizes within the workspace; Option+Shift+F uses native fullscreen.
- Option+Q and Control+Option+Backspace close the focused window.
- Option+Tab returns to the previous workspace. Option+Shift+Tab moves the entire
  workspace to the next monitor, wrapping around.
- Control+Option+R resets and balances the tiling tree.
- Control+Option+Period reloads the config.
- Shottr, Camera Preview, the configured Apple utilities, and windows with
  Settings or Preferences in their title float.

The older AeroSpace Notes and Teams workspaces, `N` and `T`, remain available with
Option+N/T and Option+Shift+N/T.

`distribute.sh` restores the same monitor split as `yabai/distribute.sh`:

| Monitor | Workspaces |
| --- | --- |
| macOS main display, currently the MacBook screen | `S`, `6`, `7`, `9` |
| First non-main display, currently the external monitor | `1`, `2`, `3`, `4`, `5`, `8` |

It runs at startup and with Control+Option+D. Press that shortcut after connecting
a monitor. On a single display it does nothing. `N` and `T` are not redistributed.
The script follows the macOS main-display setting, just like the yabai script.

Fixed `workspace-to-monitor-force-assignment` rules would prevent manual workspace
moves. Using a startup/manual command lets Option+Shift+Tab keep working.

## Differences to expect

AeroSpace workspaces are separate from native macOS Spaces. Existing yabai Space
labels and window assignments do not become AeroSpace workspaces automatically.

Option+Period uses AeroSpace's accordion layout rather than yabai's stack layout.
Option+Shift+Period and Control+Option+F float the focused window, rather than the
whole workspace. Control+Option+B returns that window to tiling. The
Control+Option+Shift+H/J/K/L shortcuts join neighboring windows into a container;
they do not set yabai's insertion point for a future window.

## Switch on the MacBook

Run these commands in a terminal on the MacBook as your normal user.

### 1. Install the official package and link the config

```sh
brew install --cask nikitabobko/tap/aerospace
mkdir -p ~/.config/aerospace
ln -s ~/dotfiles/aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml
```

Neither `~/.aerospace.toml` nor `~/.config/aerospace/aerospace.toml` existed when
checked. If the link command now reports an existing file, inspect it first.
AeroSpace reports an error if configs exist in both locations.

The Nix Homebrew and Home Manager declarations also include AeroSpace now. The
commands above let you switch without rebuilding the whole system. Home Manager
can adopt this same-target symlink on the next normal rebuild.

### 2. Save the labels, then disable yabai

```sh
~/.config/yabai/labels.sh save
cp ~/.cache/yabai-labels.json ~/.cache/yabai-labels.before-aerospace.json

launchctl disable "gui/$(id -u)/com.asmvik.yabai"
/opt/homebrew/bin/yabai --stop-service
```

`launchctl disable` keeps yabai off across login and reboot. The package, service
files, and config stay installed for switching back.

Keep skhd running with only the speech-to-text shortcuts. AeroSpace cannot launch
the recorder itself because its app bundle does not declare microphone use:

```sh
launchctl enable "gui/$(id -u)/com.koekeishiya.skhd"
/opt/homebrew/bin/skhd --stop-service
/usr/libexec/PlistBuddy -c 'Add :ProgramArguments:1 string -c' \
  ~/Library/LaunchAgents/com.koekeishiya.skhd.plist
/usr/libexec/PlistBuddy -c 'Add :ProgramArguments:2 string /Users/tuliopaim/dotfiles/skhd/aerospace.skhdrc' \
  ~/Library/LaunchAgents/com.koekeishiya.skhd.plist
/opt/homebrew/bin/skhd --start-service
```

The two `PlistBuddy` commands are only needed once after skhd installs its service.
Reinstalling that service may replace the arguments.

Confirm these produce no process IDs before opening AeroSpace:

```sh
pgrep -x yabai
```

### 3. Bring your windows onto one native desktop per screen

Open Mission Control and drag the windows you want to use onto one native Desktop
on each monitor. Exit native fullscreen for windows you want AeroSpace to tile.
You can keep the other Desktops empty for an easier return to yabai.

Use AeroSpace shortcuts to organize windows after starting it. If an app keeps
jumping back to an old native Desktop, check its Dock icon under
**Options > Assign To** and select **None**.

Your current **Displays have separate Spaces** setting can stay enabled for the
initial switch. AeroSpace's guide recommends disabling it if you encounter focus
or cross-monitor problems. That change needs logout and makes native fullscreen
blank the other display, so use Option+F for workspace fullscreen instead.

### 4. Start AeroSpace and grant Accessibility access

```sh
open -a AeroSpace
```

Allow AeroSpace in **System Settings > Privacy & Security > Accessibility** if
prompted. Relaunch it if requested. `start-at-login = true` makes it start on future
logins. No scripting addition or SIP change is needed for AeroSpace.

### 5. Validate and check the shortcuts

```sh
aerospace reload-config --dry-run --no-gui --warnings-as-errors
aerospace config --config-path
bash ~/dotfiles/aerospace/distribute.sh
aerospace list-workspaces --all --format '%{workspace} | %{monitor-name}'
```

The config path should point to `~/.config/aerospace/aerospace.toml`. Check:

1. Option+Return opens Ghostty.
2. Option+1 selects the external monitor; Option+0 selects `S` on the MacBook.
3. Option+Shift+2 moves a test window to workspace 2 and follows it.
4. Option+Shift+Tab moves the current workspace to the other monitor and back.
5. Control+Option+D restores the monitor split.
6. F9 starts/stops dictation through skhd.

## Switch back to yabai later

First set `start-at-login = false` in `aerospace.toml`, then reload and quit it:

```sh
aerospace reload-config
osascript -e 'tell application "AeroSpace" to quit'
```

After AeroSpace exits, re-enable and start the old services:

```sh
launchctl enable "gui/$(id -u)/com.asmvik.yabai"
launchctl enable "gui/$(id -u)/com.koekeishiya.skhd"
/opt/homebrew/bin/yabai --start-service
/opt/homebrew/bin/skhd --stop-service
/usr/libexec/PlistBuddy -c 'Delete :ProgramArguments:2' \
  ~/Library/LaunchAgents/com.koekeishiya.skhd.plist
/usr/libexec/PlistBuddy -c 'Delete :ProgramArguments:1' \
  ~/Library/LaunchAgents/com.koekeishiya.skhd.plist
/opt/homebrew/bin/skhd --start-service
```

This restores the old services, not macOS 27 scripting-addition compatibility.
Window placement will need reorganizing if you consolidated native Spaces.
If you changed **Displays have separate Spaces**, turn it back on and log out/in
before returning to yabai.

## References

- [Official installation and config guide](https://nikitabobko.github.io/AeroSpace/guide)
- [Commands, including workspace moves and config validation](https://nikitabobko.github.io/AeroSpace/commands)
- [Official Homebrew cask](https://github.com/nikitabobko/homebrew-tap/blob/main/Casks/aerospace.rb)
- [Release-specific default config](https://github.com/nikitabobko/AeroSpace/blob/v0.21.3-Beta/docs/config-examples/default-config.toml)
