#!/bin/bash
# Replaces all existing dotfiles with symlinks to the development ones for easier development 
DOTS=$(dirname "$(realpath "$0")")

for dir in "$DOTS/dots/.config"/*/; do
    name=$(basename "$dir")
    ln -snf "$dir" ~/.config/"$name"
done

for dir in "$DOTS/dots/.local"/*/; do
    name=$(basename "$dir")
    ln -snf "$dir" ~/.local/"$name"
done