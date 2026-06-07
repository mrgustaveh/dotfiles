#!/bin/bash

set -euo pipefail

WALL_DIR="$HOME/Pictures/wallpapers"
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/wallcycle-current"

mapfile -t WALLS < <(find -L "$WALL_DIR" -mindepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \))

if ((${#WALLS[@]} == 0)); then
  notify-send "wallcycle" "No wallpapers found in $WALL_DIR" 2>/dev/null || true
  exit 1
fi

CURRENT=""
[[ -f "$STATE_FILE" ]] && CURRENT=$(cat "$STATE_FILE")

if ((${#WALLS[@]} > 1)) && [[ -n "$CURRENT" ]]; then
  CURRENT_REAL=$(readlink -f "$CURRENT" 2>/dev/null || printf '%s' "$CURRENT")
  CANDIDATES=()
  for WALL in "${WALLS[@]}"; do
    WALL_REAL=$(readlink -f "$WALL" 2>/dev/null || printf '%s' "$WALL")
    [[ "$WALL_REAL" != "$CURRENT_REAL" ]] && CANDIDATES+=("$WALL")
  done
  ((${#CANDIDATES[@]} > 0)) || CANDIDATES=("${WALLS[@]}")
else
  CANDIDATES=("${WALLS[@]}")
fi

WALL=$(printf "%s\n" "${CANDIDATES[@]}" | shuf -n 1)

hyprctl hyprpaper preload "$WALL"
hyprctl hyprpaper wallpaper ",$WALL"
[[ -n "$CURRENT" ]] && hyprctl hyprpaper unload "$CURRENT" 2>/dev/null || true

mkdir -p "$(dirname "$STATE_FILE")"
printf '%s\n' "$WALL" > "$STATE_FILE"
notify-send "Wallpaper changed" "$(basename "$WALL")" --icon "$WALL" 2>/dev/null || true
