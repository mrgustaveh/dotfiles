# dotfiles

Hyprland desktop configs managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

Configs live at the repo root:

```text
dotfiles/
├── .config/
│   ├── hypr/             # Hyprland, scripts, keybinds
│   ├── waybar/           # Status bar
│   ├── kitty/            # Terminal
│   ├── rofi/             # App launcher / menus
│   └── btop/             # System monitor
├── .local/share/applications/
├── wallpapers/           # Linked to ~/Pictures/wallpapers on install
├── install.sh
└── packages.txt
```

`install.sh` uses [GNU Stow](https://www.gnu.org/software/stow/) to link `.config/` and `.local/` into `$HOME`. A generated `stow/` directory (gitignored) holds Stow packages; edits in `.config/...` apply immediately via the symlinks. Re-run `./install.sh` after adding new config directories.

## Fresh machine setup

```bash
git clone git@github.com:YOUR_USER/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Skip apt installs if packages are already installed:

```bash
SKIP_PACKAGES=1 ./install.sh
```

## After install

1. Log into Hyprland
2. Launch waybar: `~/.config/waybar/launch.sh`

Wallpapers live in `wallpapers/` in the repo and are linked to `~/Pictures/wallpapers` on install.

## Keybinds (quick reference)

| Binding | Action |
|---|---|
| Super+Return | Terminal (kitty) |
| Super+E | Yazi (new workspace) |
| Super+G | Chrome (new workspace) |
| Super+X | btop (new workspace) |
| Super+[ / Super+] | Previous / next workspace |
| Super+1–6 | Go to workspace |
| Super+Shift+1–6 | Move window to workspace |

## Updating configs

Edit files in `.config/...`, then re-run install if you add new packages:

```bash
cd ~/workspaces/dotfiles
SKIP_PACKAGES=1 ./install.sh
```

Or restow manually:

```bash
cd ~/workspaces/dotfiles
./install.sh
```

## Push to GitHub

```bash
cd ~/dotfiles
git init
git add .
git commit -m "Initial dotfiles"
gh repo create dotfiles --private --source=. --push
```

Use a **private** repo unless you have audited for secrets.

## Optional: machine-specific overrides

Create untracked files under `local/` or add a host profile later if laptop/desktop configs diverge.

#### fonts (manual setup)
- Step 1 — Install the font:
  mkdir -p ~/.local/share/fonts/JetBrainsMono
  curl --retry 3 --retry-delay 5 -fsSL \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip" \
    -o /tmp/JetBrainsMono.zip
  unzip -q /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
  fc-cache -f ~/.local/share/fonts
  rm /tmp/JetBrainsMono.zip


- Step 2 — Restart waybar:
  pkill waybar; ~/.config/waybar/launch.sh &
