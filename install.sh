#!/usr/bin/env bash
#
# install.sh - install the Hyprvibr setup from this repo onto the current machine.
#
#   ./install.sh              ask whether to copy or symlink
#   ./install.sh --copy       copy files into place
#   ./install.sh --symlink    symlink files into place (edits stay in the repo)
#   ./install.sh -h           help
#
# Installs:
#   bin/hyprvibr-add                      -> ~/.local/bin/hyprvibr-add
#   addons/hyprvibr.lua                   -> ~/.config/hypr/addons/hyprvibr.lua
#   addons/hyprvibr-app-rules.lua.conf    -> ~/.config/hypr/addons/hyprvibr-app-rules.lua.conf
#
# Existing files are never overwritten without asking, and are backed up first.
# hyprland.lua is never edited; the script only tells you if the loader line is missing.

set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
ADDONS_DIR="$HOME/.config/hypr/addons"
HYPR_LUA="$HOME/.config/hypr/hyprland.lua"
STAMP="$(date +%Y%m%d-%H%M%S)"
MODE=""

usage() {
    sed -n '3,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
    "")         ;;
    --copy)     MODE="copy" ;;
    --symlink)  MODE="symlink" ;;
    -h|--help)  usage; exit 0 ;;
    *)          usage >&2; exit 1 ;;
esac

# ---------- choose install method ----------
if [[ -z "$MODE" ]]; then
    echo "How should files be installed?"
    echo "  c) Copy     - independent copies in your config"
    echo "  s) Symlink  - config points at this repo, so edits (and new rules) land here"
    while true; do
        read -rp "Choose [c/s]: " ans
        case "$ans" in
            [Cc]*) MODE="copy"; break ;;
            [Ss]*) MODE="symlink"; break ;;
            *) echo "Please enter c or s." ;;
        esac
    done
fi
echo "Install method: $MODE"
echo

# ---------- install one file ----------
install_file() {
    local src="$REPO_DIR/$1" dest="$2" label="$3"

    echo "--- $label"
    if [[ ! -f "$src" ]]; then
        echo "  SKIPPED: $1 is not in the repo. Is your clone complete?"
        echo
        return
    fi

    mkdir -p "$(dirname "$dest")"

    # Already installed the way we want?
    if [[ "$MODE" == "symlink" && -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        echo "  Already linked: $dest"; echo; return
    fi
    if [[ "$MODE" == "copy" && -f "$dest" && ! -L "$dest" ]] && cmp -s "$src" "$dest"; then
        echo "  Already up to date: $dest"; echo; return
    fi

    # Something else is there: ask, then back it up
    if [[ -e "$dest" || -L "$dest" ]]; then
        read -rp "  $dest already exists. Replace it (a backup is kept)? [y/N]: " ow
        if [[ ! "$ow" =~ ^[Yy]$ ]]; then
            echo "  Kept existing file."; echo; return
        fi
        mv "$dest" "$dest.pre-install.$STAMP" || { echo "  Could not back up $dest"; echo; return; }
        echo "  Backed up to $dest.pre-install.$STAMP"
    fi

    if [[ "$MODE" == "symlink" ]]; then
        chmod +x "$src" 2>/dev/null || true
        ln -s "$src" "$dest" && echo "  Linked: $dest -> $src"
    else
        cp "$src" "$dest" && echo "  Copied: $dest"
    fi
    echo
}

install_file "bin/hyprvibr-add"                    "$BIN_DIR/hyprvibr-add"                          "hyprvibr-add (helper script)"
install_file "addons/hyprvibr.lua"                 "$ADDONS_DIR/hyprvibr.lua"                       "hyprvibr.lua (Lua addon)"
install_file "addons/hyprvibr-app-rules.lua.conf"  "$ADDONS_DIR/hyprvibr-app-rules.lua.conf"        "hyprvibr-app-rules.lua.conf (rules)"

# ---------- post-install checks ----------
echo "=== Checks ==="

for cmd in hyprctl jq; do
    command -v "$cmd" >/dev/null 2>&1 || echo "! Missing required tool: $cmd (needed by hyprvibr-add)"
done
command -v fzf >/dev/null 2>&1 || echo "- fzf not found (optional): hyprvibr-add will use a numbered list instead."

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "! $BIN_DIR is not in your PATH, so 'hyprvibr-add' won't be found by name." ;;
esac

LOADER='dofile(os.getenv("HOME") .. "/.config/hypr/addons/hyprvibr.lua")'
if [[ -f "$HYPR_LUA" ]]; then
    if grep -q 'addons/hyprvibr.lua' "$HYPR_LUA"; then
        echo "- hyprland.lua already loads hyprvibr.lua."
    else
        echo "! hyprland.lua does not load the addon yet. Add this line to $HYPR_LUA:"
        echo
        echo "    $LOADER"
        echo
    fi
else
    echo "! $HYPR_LUA not found. Once it exists, add this line to it:"
    echo
    echo "    $LOADER"
    echo
fi

echo "- The Hyprvibr plugin itself is not part of this repo; install it separately."
echo
echo "Done. Run 'hyprctl reload' to apply."
