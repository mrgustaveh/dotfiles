#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}"
PACKAGES="${DOTFILES}/packages.txt"
STOW_DIR="${DOTFILES}/stow"

CONFIG_DIRS=(
  btop
  hypr
  kitty
  rofi
  swaync
  waybar
)

log() {
  printf '==> %s\n' "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

install_packages() {
  if [[ "${SKIP_PACKAGES:-0}" == "1" ]]; then
    log "Skipping package install (SKIP_PACKAGES=1)"
    return
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    log "apt-get not found; install packages from packages.txt manually"
    return
  fi

  log "Enabling universe repository"
  sudo add-apt-repository -y universe

  log "Adding Hyprland PPA (hyprland, hypridle, hyprlock)"
  sudo add-apt-repository -y ppa:cppiber/hyprland

  install_brave

  log "Installing apt packages"
  sudo apt-get update
  mapfile -t pkgs < <(grep -Ev '^\s*(#|$)' "$PACKAGES")
  sudo apt-get install -y "${pkgs[@]}"

  install_jetbrains_nerd_font
  install_yazi
}

install_brave() {
  if command -v brave-browser >/dev/null 2>&1; then
    log "Brave already installed, skipping"
    return
  fi
  log "Adding Brave apt repository"
  curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y brave-browser
}

install_jetbrains_nerd_font() {
  if fc-list | grep -q "JetBrainsMono Nerd Font"; then
    log "JetBrainsMono Nerd Font already installed, skipping"
    return
  fi
  log "Installing JetBrainsMono Nerd Font from GitHub releases"
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
    -o "${tmp}/JetBrainsMono.zip"
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
  unzip -q "${tmp}/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/JetBrainsMono"
  fc-cache -f "$HOME/.local/share/fonts"
  rm -rf "$tmp"
}

install_yazi() {
  if command -v yazi >/dev/null 2>&1; then
    log "yazi already installed, skipping"
    return
  fi
  log "Installing yazi from GitHub releases"
  local tmp
  tmp="$(mktemp -d)"
  local archive="${tmp}/yazi.zip"
  curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip" \
    -o "$archive"
  unzip -q "$archive" -d "$tmp"
  sudo install -m 0755 "${tmp}/yazi-x86_64-unknown-linux-gnu/yazi" /usr/local/bin/yazi
  rm -rf "$tmp"
}

stage_tree() {
  local src="$1"
  local dest="$2"

  mkdir -p "$dest"

  while IFS= read -r -d '' path; do
    local rel="${path#$src/}"
    [[ -n "$rel" ]] && mkdir -p "${dest}/${rel}"
  done < <(find "$src" -type d -print0)

  while IFS= read -r -d '' path; do
    local rel="${path#$src/}"
    local target="${dest}/${rel}"

    mkdir -p "$(dirname "$target")"
    ln -sfn "$(realpath --relative-to="$(dirname "$target")" "$path")" "$target"
  done < <(find "$src" -type f -print0)
}

stage_config_package() {
  local app="$1"
  local stage="${STOW_DIR}/config/${app}"
  local pkg="${stage}/pkg/dotfiles/${app}"
  local src="${DOTFILES}/.config/${app}"

  rm -rf "$stage"
  stage_tree "$src" "$pkg"
  rm -rf "${pkg}/home"

  stow -d "${stage}/pkg" -t "${HOME}/.config" --restow dotfiles
  rm -rf "${HOME}/.config/${app}/home"
}

stage_local_package() {
  local stage="${STOW_DIR}/local"
  local pkg="${stage}/pkg/share"
  local src="${DOTFILES}/.local/share"

  rm -rf "$stage"
  stage_tree "$src" "$pkg"

  stow -d "${stage}/pkg" -t "${HOME}/.local" --restow share
}

mirror_config_dirs() {
  local base="$1"
  local app="$2"
  local root="${DOTFILES}/.config/${app}"

  find "$root" -type d ! -path "$root" -print0 | while IFS= read -r -d '' path; do
    local rel="${path#$root/}"
    mkdir -p "${base}/${rel}"
  done
}

prepare_stow_targets() {
  mkdir -p "${HOME}/.config" "${HOME}/.local/share/applications"

  for dir in "${CONFIG_DIRS[@]}"; do
    rm -rf "${HOME}/.config/${dir}"
    mkdir -p "${HOME}/.config/${dir}"
    mirror_config_dirs "${HOME}/.config/${dir}" "$dir"
  done

  mkdir -p "${HOME}/.local/share/applications"
}

link_dotfiles() {
  require_cmd stow

  log "Linking dotfiles into ${TARGET} with GNU Stow"
  prepare_stow_targets

  for dir in "${CONFIG_DIRS[@]}"; do
    stage_config_package "$dir"
  done

  stage_local_package
}

make_scripts_executable() {
  log "Making scripts executable"
  find "${DOTFILES}/.config/hypr/scripts" -type f -exec chmod +x {} +
  find "${DOTFILES}/.config/waybar/scripts" -type f -exec chmod +x {} +
  find "${DOTFILES}/.config/rofi/scripts" -type f -exec chmod +x {} +
  find "${DOTFILES}/.config/waybar/launch.sh" -type f -exec chmod +x {} +
}

link_wallpapers() {
  log "Linking wallpapers to ~/Pictures/wallpapers"
  mkdir -p "${HOME}/Pictures"
  if [[ -e "${HOME}/Pictures/wallpapers" && ! -L "${HOME}/Pictures/wallpapers" ]]; then
    rm -rf "${HOME}/Pictures/wallpapers"
  fi
  ln -sfnT "${DOTFILES}/wallpapers" "${HOME}/Pictures/wallpapers"
}

setup_runtime_dirs() {
  log "Creating runtime directories"
  mkdir -p "${HOME}/Pictures/screenshots"
}

setup_desktop_entries() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    log "Updating desktop database"
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
  fi
}

main() {
  if [[ "${SKIP_PACKAGES:-0}" != "1" ]] && command -v apt-get >/dev/null 2>&1; then
    log "Ensuring bootstrap dependencies"
    sudo apt-get update -qq
    sudo apt-get install -y curl unzip software-properties-common
  fi
  install_packages
  link_dotfiles
  link_wallpapers
  make_scripts_executable
  setup_runtime_dirs
  setup_desktop_entries

  log "Done"
  cat <<EOF

Next steps:
  1. Log into Hyprland (or run: hyprctl reload)
  2. Start waybar: ~/.config/waybar/launch.sh

EOF
}

main "$@"
