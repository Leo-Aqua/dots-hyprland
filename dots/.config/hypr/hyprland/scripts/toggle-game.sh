# ~/.config/hypr/hyprland/scripts/toggle-game.sh
#!/bin/bash

GAME_WS=$(hyprctl clients -j | jq '[.[] | select(.workspace.name == "special:game")] | length')

hyprctl dispatch togglespecialworkspace game

if [ "$GAME_WS" -eq 0 ]; then
    hyprctl dispatch submap protected
else
    hyprctl dispatch submap reset
fi