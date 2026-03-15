DOTS=$(dirname "$(realpath $0)")

rm -rf ~/.config/quickshell
ln -s $DOTS/dots/.config/quickshell ~/.config/quickshell

rm -rf ~/.config/hypr
ln -s $DOTS/dots/.config/hypr ~/.config/hypr
   # repeat for any other dirs you plan to modify
