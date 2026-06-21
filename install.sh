#!/bin/bash

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

OS="$(uname -s)"

# Get the last git commit epoch for a repo path (file or directory).
repo_epoch() {
  git -C "$REPO_DIR" log -1 --format="%ct" -- "${1#$REPO_DIR/}"
}

# Get the modification epoch of a system path.
# For a directory, finds the most recently modified file inside it.
system_epoch() {
  if [ -d "$1" ]; then
    if [ "$OS" = "Darwin" ]; then
      find "$1" -type f -exec stat -f "%m" {} + 2>/dev/null | sort -rn | head -1
    else
      find "$1" -type f -exec stat -c "%Y" {} + 2>/dev/null | sort -rn | head -1
    fi
  elif [ -f "$1" ]; then
    if [ "$OS" = "Darwin" ]; then
      stat -f "%m" "$1"
    else
      stat -c "%Y" "$1"
    fi
  else
    echo 0
  fi
}

# Format an epoch timestamp as a human-readable date.
format_date() {
  if [ "$OS" = "Darwin" ]; then
    date -r "$1" '+%Y-%m-%d %H:%M'
  else
    date -d "@$1" '+%Y-%m-%d %H:%M'
  fi
}

# Check if an app is installed (supports both CLI commands and .app bundles).
is_installed() {
  local name="$1"
  case "$name" in
    *.app)
      [ "$OS" = "Darwin" ] && { [ -d "/Applications/$name" ] || [ -d "$HOME/Applications/$name" ]; }
      ;;
    *)     command -v "$name" &>/dev/null ;;
  esac
}

# Check nvim version is at least 0.11
check_nvim_version() {
  if ! command -v nvim &>/dev/null; then
    return 1
  fi

  local version=$(nvim --version | head -1 | sed 's/NVIM v//' | cut -d. -f1,2)
  local major=$(echo "$version" | cut -d. -f1)
  local minor=$(echo "$version" | cut -d. -f2)

  if [ "$major" -eq 0 ] && [ "$minor" -lt 11 ]; then
    echo "ERROR: nvim version 0.11+ is required, but found v$version"
    echo "Please upgrade nvim to version 0.11 or later"
    return 1
  fi

  echo "INFO nvim version v$version detected"
  return 0
}

install_config() {
  local src="$1" dest="$2" name="$3" app="$4"
  local repo_ts system_ts

  if ! is_installed "$app"; then
    echo "SKIP $name: $app is not installed"
    return
  fi

  repo_ts="$(repo_epoch "$src")"
  system_ts="$(system_epoch "$dest")"

  if [ -z "$repo_ts" ]; then
    echo "SKIP $name: no git history found"
    return
  fi

  if [ "$system_ts" -gt "$repo_ts" ] 2>/dev/null; then
    echo "WARN $name: system copy is newer (system=$(format_date "$system_ts"), repo=$(format_date "$repo_ts"))"
    printf "  Install older repo version anyway? [y/N] "
    read -r answer
    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
      echo "SKIP $name"
      return
    fi
  fi

  if [ -e "$dest" ]; then
    echo "Backing up $dest -> ${dest}.bak"
    # Remove old backup if it exists
    rm -rf "${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  mkdir -p "$(dirname "$dest")"
  if [ -d "$src" ]; then
    cp -R "$src" "$dest"
  else
    cp "$src" "$dest"
  fi
  echo "OK   $name: copied to $dest"
}

main() {
  install_config "$REPO_DIR/kitty"                    "$HOME/.config/kitty"                    "kitty"      "kitty"
  install_config "$REPO_DIR/tmux.conf"                "$HOME/.tmux.conf"                       "tmux"       "tmux"

  # Check nvim version before installing
  if ! check_nvim_version; then
    echo "Skipping nvim installation due to version requirement"
    return 0
  fi

  install_config "$REPO_DIR/nvim"                     "$HOME/.config/nvim"                     "nvim"       "nvim"
  if [ "$OS" = "Darwin" ]; then
    install_config "$REPO_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json" "karabiner"  "Karabiner-Elements.app"
  fi

  echo "Done!"
}

# Run main function
main
