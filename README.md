This is the personal configuration of various arch apps for @yifever.
You are free to copy these configurations, or give me suggestions on what are the best configs.

## Configs

- **kitty** - terminal emulator
- **nvim** - Neovim editor
- **karabiner** - keyboard customization (macOS)

## Usage

### Install configs to your system

```sh
./install.sh
```

Copies repo configs to `~/.config/`. Skips apps that aren't installed and skips configs where your system copy is newer than the last git commit.

### Update repo from your system

```sh
./update.sh
```

Copies your system configs back into the repo. Skips configs where the repo copy is already newer than the system copy.
