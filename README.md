# HyperPower for Omarchy

A toggle for Omarchy that shakes the entire desktop, like the
[HyperPower](https://hyper.is/store/hyperpower) plugin for Hyper.

One click on the lightning bolt in the bar and every tiled window jitters.
The gaps, the border size, and the workspace padding change to random values
about 16 times each second. Click again and the original values come back.

## Requirements

- Omarchy with Hyprland 0.56 or newer. The script also supports older
  Hyprland releases that still have `hyprctl keyword`.

## Install

```bash
omarchy plugin add https://github.com/bjarneo/omarchy-hyperpower.git --enable
```

The `--enable` flag adds the widget to the bar. Without it, enable the plugin
later with `omarchy plugin enable bjarneo.hyperpower`.

## Use

- Click the lightning bolt in the bar. Red means the shake runs.
- Or run `omarchy-shell hyperpower toggle`.
- Or bind a key to `omarchy-shell hyperpower toggle`.

## Keybinding

Add the rebind or bind call to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + SHIFT + H", "HyperPower", "omarchy-shell hyperpower toggle")
```

## Settings

The widget takes one setting, `intensity`. The value is the maximum random
gap in pixels. The range is 0 to 64 and the default is 16.

Set it in the bar settings menu, or inline in `~/.config/omarchy/shell.json`:

```json
{ "id": "bjarneo.hyperpower", "intensity": 24 }
```

## Command line

The plugin ships a standalone script at `bin/hyperpower`. The service, the
bar, and a keybinding all use the same script.

```bash
bin/hyperpower status              # prints active or inactive
bin/hyperpower start               # start the shake
bin/hyperpower start --intensity 32
bin/hyperpower start --rate 40     # 40 ms between frames
bin/hyperpower stop                # stop and restore the saved values
bin/hyperpower toggle
```

The script writes its state to `$XDG_RUNTIME_DIR/omarchy-hyperpower/`.
It saves the original Hyprland values before the first frame and restores
them on `stop`. A shell restart stops the shake, because the state lives
with the session.

## How it works

Hyprland 0.56 changed the config parser to Lua, so `hyprctl keyword` no
longer applies at runtime. The script calls `hyprctl eval` with
`hl.config(...)` instead. On older releases it falls back to
`hyprctl keyword`.

## Uninstall

```bash
omarchy plugin remove bjarneo.hyperpower
```

Remove the keybinding from `~/.config/hypr/bindings.lua` if you added one.
