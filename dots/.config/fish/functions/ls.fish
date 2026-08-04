function ls --wraps='bash -c "eza $1 --icons"' --wraps='exa --icons=auto' --description 'alias ls exa --icons=auto'
    exa --icons=auto $argv
end
