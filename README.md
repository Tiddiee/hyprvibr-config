# Hyprvibr Config

Per-app saturation for Hyprland, configured through a HyDE Lua addon and the
Hyprvibr plugin. Rules live in a plain-text file, so adding a new game
never requires editing Lua. A helper script, `hyprvibr-add`, adds and removes rules for you.

> The Hyprvibr plugin itself is **not** included in this repo. Install it separately.

## Repo layout

```
hyprvibr-config/
├── README.md
├── install.sh                              Install onto a machine (copy or symlink)
├── collect.sh                              Pull your live files into this repo
├── bin/
│   └── hyprvibr-add                        Helper script (add / remove rules)
└── addons/
    ├── hyprvibr.lua                        Main Lua addon
    └── hyprvibr-app-rules.lua.conf         Rules file (empty template)
```

Where files end up on a machine:

| Repo file | Installed to |
| --- | --- |
| `bin/hyprvibr-add` | `~/.local/bin/hyprvibr-add` |
| `addons/hyprvibr.lua` | `~/.config/hypr/addons/hyprvibr.lua` |
| `addons/hyprvibr-app-rules.lua.conf` | `~/.config/hypr/addons/hyprvibr-app-rules.lua.conf` |

## Install

```bash
git clone <your-repo-url> hyprvibr-config
cd hyprvibr-config
./install.sh
```

`install.sh` asks whether to **copy** or **symlink** the files (or pass `--copy` / `--symlink`).

- **Copy:** independent files in your config. Simple and safe.
- **Symlink:** your config points at the repo, so edits and new rules are tracked by git.
  Note that rules added with `hyprvibr-add` then show up as changes in the repo.

Existing files are never overwritten without asking, and are backed up as
`<file>.pre-install.<timestamp>` first. `hyprland.lua` is never edited.

After installing, make sure `~/.config/hypr/hyprland.lua` loads the addon:

```lua
dofile(os.getenv("HOME") .. "/.config/hypr/addons/hyprvibr.lua")
```

The installer tells you if this line is missing. Then reload:

```bash
hyprctl reload
```

### Requirements

- Hyprland with the Hyprvibr plugin
- `hyprctl` and `jq` (for `hyprvibr-add`)
- `fzf` (optional, gives a multi-select picker; otherwise a numbered list is used)
- `~/.local/bin` in your `PATH`

## Updating the repo from your working machine

`addons/hyprvibr.lua` is taken from your live config so the repo matches what you actually run:

```bash
./collect.sh            # copies ~/.config/hypr/addons/hyprvibr.lua into addons/
./collect.sh --rules    # also copies your live rules file (replaces the empty template)
```

The rules file is not collected by default, because it is your personal list of apps.

## Using `hyprvibr-add`

| Command | Action |
| --- | --- |
| `hyprvibr-add` | Add open windows to the rules file |
| `hyprvibr-add -r` | Remove existing rules |
| `hyprvibr-add -h` | Show help |

**Adding:** lists open windows by `initialClass` and title (one entry per initialClass; ones that already
have a rule are marked `[already in rules]`). Select several at once (fzf: Tab to toggle, Enter to
confirm; otherwise type numbers like `1 3 5`). For each one you enter a saturation (default
`2.2`) and a comment (default is the window title). Lines are appended to the rules file, and you
are asked whether to reload Hyprland.

**Removing:** lists every active rule as `initialClass | saturation | comment`, with `[open]` on apps that
are currently running. Select, confirm, and the lines are deleted permanently (no backup is made).
Comment lines and blank lines are never touched.

## Rules file format

```text
# Format: initialClass | saturation # comment about the app

steam_app_4000 | 2.2 # Garry's Mod
```

- First field: the window's `initialClass`. Second field: saturation.
- Text after `#` on a rule line is a comment.
- Lines starting with `#` and blank lines are ignored.

### Finding window classes by hand

```bash
hyprctl -j clients | jq '.[] | {title, class, initialClass}'
hyprctl -j activewindow | jq '{title, class, initialClass}'
```

The script writes `initialClass` (the class a window had when it first opened), which stays fixed even if the live `class` changes later. If the live `class` differs, the picker shows it as `(class: ...)` for reference.

## How the Lua addon works

`hyprvibr.lua`:

- Checks whether `hl.plugin.hyprvibr` is available.
- Reads rules from `hyprvibr-app-rules.lua.conf`, ignoring blank lines and `#` comments.
- Parses each rule into a window class and a numeric saturation.
- Registers valid entries with `hl.plugin.hyprvibr.hyprvibr_app()`.
- Prints a message if a rule is invalid or the rules file cannot be opened.
- Keeps the plugin reload fallback if Hyprvibr is unavailable.

**Trailing comments:** `hyprvibr-add` writes `# comment` after the saturation on the same line.
The parser strips everything from the first `#` onward before reading the rule, so
`steam_app_4000 | 2.2 # Garry's Mod` is read as class `steam_app_4000`, saturation `2.2`.
A `|` inside the comment is also safe. A line with a missing or non-numeric saturation is
skipped and logged as `[hyprvibr] Invalid rule: ...`.

## Validation

```bash
lua -e 'assert(loadfile(os.getenv("HOME") .. "/.config/hypr/addons/hyprvibr.lua"))'
```

This only checks syntax. It does not verify plugin integration or that rules are applied.
Test the app after `hyprctl reload`.

## Recovery

`install.sh` keeps backups of anything it replaces as `<file>.pre-install.<timestamp>`. Restore one
by moving it back over the installed file.
