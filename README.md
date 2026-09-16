# HyperPower for Omarchy

A toggle for Omarchy that shakes the entire desktop while you type, like the
[HyperPower](https://hyper.is/store/hyperpower) plugin for Hyper.

Every key press rewrites the window gaps, the border size, and the workspace
padding with random values. The shake stops about 160 ms after the last key
and the original values come back. Click the switch in the bar to turn it on
or off.

## Requirements

- Omarchy with Hyprland 0.56 or newer. The shake uses the Hyprland Lua config
  API, `input.keyboard.key` events, and `hl.config`.

## Install

```bash
omarchy plugin add https://github.com/bjarneo/omarchy-hyperpower.git --enable
```

The `--enable` flag adds the widget to the bar. Without it, enable the plugin
later with `omarchy plugin enable bjarneo.hyperpower`.

## Use

- Click the switch in the bar. Red means the shake runs.
- Or run `omarchy-shell hyperpower toggle`.
- Or bind a key to `omarchy-shell hyperpower toggle`.

## Keybinding

Add the bind call to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + SHIFT + H", "HyperPower", "omarchy-shell hyperpower toggle")
```

## Settings

The widget takes one setting, `intensity`. The value is the maximum random
gap in pixels. The range is 0 to 64 and the default is 16. The value 0 keeps
the border flicker and removes the gap movement.

Set it in the bar settings menu, or inline in `~/.config/omarchy/shell.json`:

```json
{ "id": "bjarneo.hyperpower", "intensity": 24 }
```

## Command line

The plugin ships a standalone script at `bin/hyperpower`. The service, the
bar, and a keybinding all use the same script.

```bash
bin/hyperpower status              # prints active or inactive
bin/hyperpower start               # shake on every key press
bin/hyperpower start --intensity 32
bin/hyperpower stop                # remove the listener and restore the values
bin/hyperpower toggle
```

## How it works

The script runs `hyprctl eval` with Lua code that registers a listener for the
Hyprland event `input.keyboard.key`. Hyprland calls the listener on every key
press, and the listener jitters the gaps through `hl.config`. An `hl.timer`
restores the snapshot after the last key.

The listener runs inside Hyprland, so the plugin never reads input devices and
needs no extra permissions. A Hyprland config reload removes the listener and
the shake turns off. The bar shows the state within two seconds.

## Uninstall

```bash
omarchy plugin remove bjarneo.hyperpower
```

Remove the keybinding from `~/.config/hypr/bindings.lua` if you added one.
