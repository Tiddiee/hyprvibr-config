# hyprvibr-config

My setup for per-app saturation on Hyprland using the Hyprvibr plugin.

Instead of hard-coding apps in Lua, the apps and their saturation values live inside a simple text file. A small helper script, `hyprvibr-add`, lets you add or remove apps from that file by picking them from your open windows, so you never have to edit anything by hand.

The [Hyprvibr](https://github.com/devcexx/hyprvibr) plugin itself isn't included here. You'll need to install it separately.

## What's in here

| File | What it does |
| --- | --- |
| `bin/hyprvibr-add` | Helper script for adding and removing apps |
| `addons/hyprvibr.lua` | Lua addon that reads the rules file and applies the settings |
| `addons/hyprvibr-app-rules.lua.conf` | The list of apps and their saturation (starts empty) |
| `install.sh` | Puts everything in the right place |

## Requirements

- Hyprland with the Hyprvibr plugin installed
- `hyprctl` and `jq`
- `fzf` (optional, makes picking windows nicer)
- `~/.local/bin` in your `PATH`

## Installing

```bash
git clone <repo-url> hyprvibr-config
cd hyprvibr-config
./install.sh
```

The installer asks whether you want to copy the files or symlink them. You can also skip the question with `--copy` or `--symlink`.

- **Copy** puts independent copies in your config. This is the simple option.
- **Symlink** points your config at this repo, so any change shows up in git. That includes rules you add with `hyprvibr-add`.

Files end up here:

| From the repo | Installed to |
| --- | --- |
| `bin/hyprvibr-add` | `~/.local/bin/hyprvibr-add` |
| `addons/hyprvibr.lua` | `~/.config/hypr/addons/hyprvibr.lua` |
| `addons/hyprvibr-app-rules.lua.conf` | `~/.config/hypr/addons/hyprvibr-app-rules.lua.conf` |

If a file already exists, the installer asks before replacing it and saves the old one as `<file>.pre-install.<timestamp>`. It never edits your `hyprland.lua`.

Once installed, make sure your `~/.config/hypr/hyprland.lua` loads the addon. The installer will tell you if the line is missing:

```lua
dofile(os.getenv("HOME") .. "/.config/hypr/addons/hyprvibr.lua")
```

Then reload Hyprland:

```bash
hyprctl reload
```

## Using hyprvibr-add

```bash
hyprvibr-add        # add apps
hyprvibr-add -r     # remove apps
hyprvibr-add -h     # help
```

**Adding an app**

1. Run `hyprvibr-add` with the app open. It lists your open windows.
2. Pick one or more. With fzf, use Tab to select and Enter to confirm. Without fzf, type the numbers, like `1 3 5`.
3. For each one, enter a saturation value (default `2.2`) and a short comment (default is the window title).
4. It adds the rule to the end of the rules file, then asks if you want to reload Hyprland.

Apps that already have a rule are marked `[already in rules]`, and you'll be asked before adding a second one.

**Removing an app**

1. Run `hyprvibr-add -r`. It lists every rule in the file, and marks the ones whose app is currently open.
2. Pick the ones you want gone and confirm.
3. Those lines are deleted for good (there's no backup), then it asks about reloading.

Comments and blank lines in the file are never touched.

## The rules file

Each rule is one line:

```text
# initialClass | saturation # comment
steam_app_240 | 2.2 # CS:Source
```

- The first part is the window's `initialClass`, which is the class it had when it first opened.
- The second part is the saturation value.
- Anything after a `#` is a comment, and lines starting with `#` are ignored.

The script uses `initialClass` because it stays the same for the life of the window, while the regular `class` can change. You can look up either one yourself:

```bash
hyprctl -j clients | jq '.[] | {title, class, initialClass}'
hyprctl -j activewindow | jq '{title, class, initialClass}'
```

If you'd rather skip the script, you can also edit the file by hand. Add or delete lines, then run `hyprctl reload`.

## How the Lua addon works

On load, `hyprvibr.lua` checks that the Hyprvibr plugin is available, reads the rules file, and registers each rule with the plugin. A rule with a missing or non-numeric saturation is skipped, and a message is printed. If the plugin isn't loaded, it tries to reload it through `hyprpm` instead.

You shouldn't need to touch the Lua file to add or remove apps.

To check the file for syntax errors:

```bash
lua -e 'assert(loadfile(os.getenv("HOME") .. "/.config/hypr/addons/hyprvibr.lua"))'
```

This only checks syntax. To confirm a rule really works, reload Hyprland and try the app.
