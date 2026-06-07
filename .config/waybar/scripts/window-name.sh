#!/usr/bin/env bash

class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')

case "$class" in
	kitty) echo Kitty ;;
	firefox) echo Firefox ;;
	*) hyprctl activewindow -j 2>/dev/null | jq -r '.title // empty' ;;
esac
