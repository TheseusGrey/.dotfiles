# Quickshell TUI Shell

## About

This folder contains the desktop shell for Hyprland.
It is a Quickshell config that makes a TUI frame on all four edges of the screen.

The frame provides these items:

- A status bar on the top edge.
- A workspaces rail and a system rail on the left edge.
- A context panel on the right edge.
- A footer with key hints on the bottom edge.
- An application finder.
- An OSD for volume and brightness.
- A notification list.
- A lock screen.

The shell reads its colors from a generated palette.
Matugen generates the palette.
You can change the palette from a wallpaper or from a fixed preset.

## Requirements

Install these programs:

- `quickshell` (the devel version)
- `matugen`
- `hyprpaper`
- `go`

Install the config in its final location:

```sh
~/.dotfiles/setup.sh
```

## Structure

```
quickshell/
├── shell.qml           # Entry point
├── services/           # Singletons: Colors, Theme, PanelState, IPC, FinderServer
├── components/         # TUI toolkit: TuiPanel, TuiButton, TuiList, ...
├── widgets/            # Blocks: Clock, StatusButtons, ContextMenu, FooterHints
├── panels/             # Top, Right, Left, Bottom surfaces plus overlays
└── scripts/
    └── qsh.go          # Source of the qsh command
```

Matugen owns these files:

- `matugen/config.toml` — image mode settings and templates.
- `matugen/templates/*` — image-driven templates. They clamp surface and text colors toward the extremes.
- `matugen/templates-raw/*` — preset templates. They use the palette unchanged.
- `matugen/presets/*.json` — fixed palettes.
- `matugen/presets/config.toml` — preset mode settings.

Matugen writes the palette to these outputs:

- `quickshell/services/Colors.qml`
- `hypr/themes/matugen_colors.lua`
- `waybar/colors.css`

## The qsh command

`qsh` is the command-line client for the shell.
It sends commands to the shell over IPC.

### Build and install

Run this command in the repo root:

```sh
just build-qsh
```

It builds `qsh` and installs it at `~/.local/bin/qsh`.

**Note:**

Hyprland does not include `~/.local/bin` in its PATH.
Hyprland keybinds that call `qsh` must use the full path:
`/home/ashe/.local/bin/qsh`.

### Command reference

The general form of a command is:

```sh
qsh <command> [options]
```

The available commands are:

| Command | Purpose |
|---|---|
| `qsh finder apps` | Open the application finder. |
| `qsh finder screenshot` | Open the screenshot finder. |
| `qsh finder keybinds` | Open the keybind finder. |
| `qsh finder toggle` | Open or close the finder. |
| `qsh panel open <context>` | Open the right panel. The context choices are `volume`, `brightness`, `wifi`, `bluetooth`, `power`, `notifications`, `keybinds`, `menu`. |
| `qsh panel left` | Expand or collapse the left rail. |
| `qsh panel close` | Close all panels. |
| `qsh osd volume <0-1> [muted]` | Show the volume OSD. The level is a number from `0` to `1`. The `muted` value is `true` or `false`. |
| `qsh osd brightness <0-1>` | Show the brightness OSD. |
| `qsh notify clear` | Clear all notifications. |
| `qsh lock` | Show the lock screen. |
| `qsh pick [--items a,b,c] [--prompt text]` | Start the interactive picker. Make a selection and print it to the standard output. |
| `qsh wallpaper <image> [--index N] [--scheme T]` | Set the wallpaper (via hyprpaper), regenerate the theme from it, and remember it. Accepts a full path or a short name matching a file in `wallpapers/`. `--index N` overrides which source colour matugen uses (0 = most dominant, the default). `--scheme T` overrides the material scheme type. |
| `qsh colors <image>` | Diagnose theming: print matugen's candidate source colours, then the palette each `--source-color-index` would produce so you can pick one. |
| `qsh sync on\|off` | Toggle whether colours track the wallpaper. `on` re-derives from the current wallpaper; `off` reverts to the last manual preset (or a black-white fallback). |
| `qsh scheme <type>` | Persist the matugen material scheme type (`scheme-expressive`, `scheme-fidelity`, ...) and regenerate the theme from the current wallpaper with it. |
| `qsh wallpapers` | List available wallpapers (basenames, one per line). |
| `qsh accent <image>` | Print the derived palette (bg, primary, secondary, tertiary) for a wallpaper without applying it. |
| `qsh theme <preset\|json-file>` | Apply a fixed theme preset. Accepts a preset name from `matugen/presets/` or the path of a matugen colors JSON file. |
| `qsh themes` | List available theme presets (names, one per line). |
| `qsh settings get <key>` | Print a persisted setting (blank if unset). |
| `qsh settings set <key> <value>` | Persist a setting to `settings.json`. |
| `qsh settings unset <key>` | Remove a persisted setting. |
| `qsh call <target> <method> [args...]` | Send a raw IPC call. |
| `qsh help` | Show the command reference. |
| `qsh version` | Show the version number. |

### Exit codes

A command exits with code `0` when it succeeds.
A command exits with a non-zero code when it fails.
It prints an error message to the standard error output.

The `pick` command has a special rule.
It exits with code `1` when you cancel the selection.

### Examples

```sh
qsh panel open volume
qsh osd volume 0.75 true
qsh call tui.shell toggleWifi
qsh theme catppuccin
git branch --format='%(refname:short)' | qsh pick --prompt "checkout branch"
```

## IPC

The shell registers one IPC target:

- The target name is `tui.shell`.

The methods of this target are:

| Method | Purpose |
|---|---|
| `lock` | Show the lock screen. |
| `toggleLeft` | Expand or collapse the left rail. |
| `closeAll` | Close all panels. |
| `toggleFinder` | Open or close the finder. |
| `openFinder <mode>` | Open the finder in the given mode. |
| `toggleVolume` | Open the volume panel. |
| `toggleBrightness` | Open the brightness panel. |
| `toggleWifi` | Open the wifi panel. |
| `toggleBluetooth` | Open the bluetooth panel. |
| `togglePower` | Open the power panel. |
| `toggleNotifications` | Open the notifications panel. |
| `toggleKeybinds` | Open the keybind panel. |
| `toggleMenu` | Open the context menu. |
| `toggleTheme` | Open the theme switcher panel. |
| `dismissNotifications` | Clear all notifications. |
| `osdVolume <level> <muted>` | Show the volume OSD. |
| `osdBrightness <level>` | Show the brightness OSD. |

To call a method directly, use this form:

```sh
qsh call tui.shell <method> [args...]
```

## Theme

You have two ways to change the theme.

### Wallpaper-driven theme

To generate the theme from a wallpaper image, run this command:

```sh
qsh wallpaper <image>
```

This command does these steps:

1. Read the dominant colors from the image.
2. Generate a `scheme-expressive` palette.
3. Clamp surface and text colors toward the extremes.
4. Write the palette to the three output files.
5. Set the wallpaper with Hyprpaper.
6. Reload Hyprland and Waybar.

### Fixed presets

To apply a fixed palette that does not come from an image, run this command:

```sh
qsh theme <preset>
```

The preset choices are:

- `default` — the fallback palette of this config.
- `catppuccin` — the catppuccin mocha palette.
- `oxide` — warm dark earthy palette.
- `nordic` — the nordic.nvim cold blue-dark palette.
- `monokai` — the Monokai palette.
- `solarized-dark` — the Solarized dark palette.
- `blackwhite` — pure monochrome, no colour accents.
- `blackwhite-accent` — monochrome bases with colour accents for accents like notifications.

You can add more presets.
Create a JSON file in `matugen/presets/` and use this form:

```sh
qsh theme <file>.json
```

A preset does not set the wallpaper.
It only changes the palette and reloads Hyprland and Waybar.

### Theme switcher panel

The right-panel context `theme` is a graphical theme switcher. Reach it from the
context menu (`☰`), the right rail (`◐` glyph), or directly with the keybind
`SUPER + C` (which is bound to `qsh panel open theme`).

In the panel you can:

- Pick a **background image**: each available wallpaper in `wallpapers/` is
  shown as a small 16:9 preview with a bar of the four colours it would derive.
  Clicking one applies it to **hyprpaper immediately** (it also preloads every
  wallpaper at startup so switching is instant) and runs `qsh wallpaper <name>`.
- Toggle **"sync colours to wallpaper"**. When on, colours always track the
  current wallpaper (`qsh sync on`). When off, the colour scheme stays as you
  last picked it from the dropdown (`qsh sync off`).
- When not syncing, pick a **colour scheme** from a dropdown of the presets
  above (this runs `qsh theme <name>`). That choice is remembered, so turning
  sync back off reverts to it; until you pick one, a black-white scheme is used
  as the fallback.
- **Open folder**: an "open folder" button next to the "background" heading
  opens `wallpapers/` in your default file manager (`xdg-open`), so you can drop
  new images in without leaving the panel.
- **Auto-refresh**: while the panel is open it re-enumerates the folder every
  ~3s. Dropping a new image in — or deleting one — updates the grid automatically
  (the model only changes when the file list actually changes, so it never
  flashes).

The panel stays open after applying so you can see the result; colours
hot-reload through the existing shell wiring.

When a wallpaper is picked it is set as the live background. `qsh wallpaper`
owns hyprpaper changes: it rewrites `hypr/hyprpaper.conf` (preloading every
image so any can be applied via IPC) and, if the chosen image wasn't already
loaded, restarts hyprpaper to pick up the new preload.

### Persisted settings

`qsh settings` reads and writes a single dedicated settings file at
`~/.config/quickshell/settings.json`. It is a flat JSON object of key/value
string pairs. The file is written atomically, so it survives crashes and can be
read or written by other tools too.

Known keys:

- `theme.syncedToWallpaper` — `"true"` or `"false"`. Controls whether the theme
  switcher derives colours from the current wallpaper (true) or uses a preset
  (false). Persisted so the choice survives a shell restart.
- `theme.wallpaper` — absolute path of the last wallpaper chosen. Used by `qsh
  sync on` to re-derive colours from it.
- `theme.preset` — name of the last manually chosen colour scheme, so turning
  sync off reverts to it.

## Useful notes

- The shell reads `Colors.qml` when it starts. Restart the shell to apply a new palette completely.
- The shell hot-reloads `Colors.qml` in most cases. If the colors do not change, restart the shell.
- Hyprland and Waybar reload automatically after `qsh wallpaper` and `qsh theme`.
- The generated palette files are committed to the dotfiles repo. Do not edit them by hand. Re-run `qsh wallpaper` or `qsh theme` to change them.
- The scheme type in `qsh wallpaper` is always `scheme-expressive`. To change it, edit the `--type` value in `quickshell/scripts/qsh.go` and rebuild.
- The default command for the app launcher is `qsh finder apps`.
Hyprland binds it to `SUPER + SPACE`.

## Troubleshooting

### A keybind does nothing

Check that the command exists:

```sh
which qsh
```

Hyprland does not include `~/.local/bin` in its PATH.
Use the full path in the keybind:
`/home/ashe/.local/bin/qsh finder apps`.

### IPC returns "Target not found."

The shell registers the target `tui.shell` when it starts.
If the message appears, the shell is not running or the config is older than the IPC change.
Restart the shell:

```sh
pkill qs
qs
```

### The theme has only one color

The image mostly has one dominant hue.
Material palettes use one hue for the whole scheme.
Run `qsh wallpaper` with an image that has several hues.
Use `qsh theme` for a fixed palette.