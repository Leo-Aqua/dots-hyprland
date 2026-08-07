# Commands to run in interactive sessions can go here
if status is-interactive
# No greeting
set fish_greeting

# Use starship
function starship_transient_prompt_func
starship module character
end
if test "$TERM" != "linux"
starship init fish | source
enable_transience
end

# Colors
if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
end

# Aliases
# kitty doesn't clear properly so we need to do this weird printing
alias clear "printf '\033[2J\033[3J\033[1;1H'"
alias celar "printf '\033[2J\033[3J\033[1;1H'"
alias claer "printf '\033[2J\033[3J\033[1;1H'"
alias pamcan pacman
alias q 'qs -c ii'
if test "$TERM" != "linux"
alias ls 'eza --icons=auto'
end
if test "$TERM" = "xterm-kitty"
alias ssh 'kitten ssh'
end
end

# Android stuff
set -gx ANDROID_HOME $HOME/Android/Sdk
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/platform-tools


set -gx GTK_USE_PORTAL 1

set -x OLLAMA_ORIGINS "http://*,https://*,onlyoffice://*"

# init z (cd alternative)
zoxide init fish | source
