#!/usr/bin/env bash
#
# collect.sh - copy your live Hyprvibr files into this repo, ready to commit.
#
#   ./collect.sh             copy ~/.config/hypr/addons/hyprvibr.lua into addons/
#   ./collect.sh --rules     also copy your live rules file (replaces the empty template)
#   ./collect.sh -h          help
#
# The rules file is NOT collected by default because it is your personal list of
# apps. Use --rules only if you want those rules in the repo.

set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDONS_DIR="$HOME/.config/hypr/addons"
WITH_RULES=0

usage() {
    sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
    "")         ;;
    --rules)    WITH_RULES=1 ;;
    -h|--help)  usage; exit 0 ;;
    *)          usage >&2; exit 1 ;;
esac

collect() {
    local live="$1" dest="$REPO_DIR/$2"

    if [[ ! -f "$live" ]]; then
        echo "Not found: $live (skipped)"
        return
    fi

    # Follow symlinks so the repo gets real content, not a link
    local real
    real="$(readlink -f "$live")"
    if [[ "$real" == "$(readlink -f "$dest" 2>/dev/null)" ]]; then
        echo "Already the repo file (symlinked): $2"
        return
    fi

    if [[ -f "$dest" ]] && ! cmp -s "$real" "$dest"; then
        read -rp "$2 already exists in the repo and differs. Overwrite? [y/N]: " ow
        [[ "$ow" =~ ^[Yy]$ ]] || { echo "Kept repo version of $2."; return; }
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$real" "$dest" && echo "Collected: $live -> $2"
}

collect "$ADDONS_DIR/hyprvibr.lua" "addons/hyprvibr.lua"

if (( WITH_RULES )); then
    collect "$ADDONS_DIR/hyprvibr-app-rules.lua.conf" "addons/hyprvibr-app-rules.lua.conf"
fi

echo
echo "Next: review the files, then commit and push (see README.md)."
