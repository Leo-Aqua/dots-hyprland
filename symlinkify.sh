#!/bin/bash
# Replaces all existing dotfiles with symlinks to the development ones for easier development 
DOTS=$(dirname "$(realpath "$0")")

for dir in "$DOTS/dots/.config"/*/; do
    name=$(basename "$dir")
    rm -rf ~/.config/"$name"
    ln -s "$dir" ~/.config/"$name"
done

for dir in "$DOTS/dots/.local"/*/; do
    name=$(basename "$dir")
    rm -rf ~/.local/"$name"
    ln -s "$dir" ~/.local/"$name"
done