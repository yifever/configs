#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Get the last git commit epoch for a repo path.
repo_epoch() {
  git -C "$REPO_DIR" log -1 --format="%ct" -- "${1#$REPO_DIR/}"
}

# Get the modification epoch of a system path.
# For a directory, finds the most recently modified file inside it.
system_epoch() {
  if [ -d "$1" ]; then
    find "$1" -type f -exec stat -f "%m" {} + 2>/dev/null | sort -rn | head -1
  elif [ -f "$1" ]; then
    stat -f "%m" "$1"
  else
    echo 0
  fi
}

update_config() {
  local src="$1" dest="$2" name="$3"
  local repo_ts system_ts

  if [ ! -e "$dest" ]; then
    echo "SKIP $name: no system config found at $dest"
    return
  fi

  repo_ts="$(repo_epoch "$src")"
  system_ts="$(system_epoch "$dest")"

  if [ -n "$repo_ts" ] && [ "$repo_ts" -gt "$system_ts" ] 2>/dev/null; then
    echo "SKIP $name: repo copy is newer (repo=$(date -r "$repo_ts" '+%Y-%m-%d %H:%M'), system=$(date -r "$system_ts" '+%Y-%m-%d %H:%M'))"
    echo "  Run install.sh to update your system config first, then re-run."
    return
  fi

  if [ -d "$src" ]; then
    rm -rf "$src"
    cp -R "$dest" "$src"
  else
    cp "$dest" "$src"
  fi
  echo "OK   $name: copied system config to repo"
}

update_config "$REPO_DIR/kitty"                    "$HOME/.config/kitty"                    "kitty"
update_config "$REPO_DIR/nvim"                     "$HOME/.config/nvim"                     "nvim"
update_config "$REPO_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json" "karabiner"

echo "Done!"
