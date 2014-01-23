alias rm="rm --one-file-system"

# hexdump
alias hd="hexdump -C"
# hexdump into less
hdl () {
    hexdump -C $argv | less
}

alias H="|head"
alias T="tail -f "
alias psg="ps aux | grep -i "

mkcd () {
    mkdir -p $argv
    cd $argv
}

export H="$HOME"
export LH="/media/lab/home/srubenst"
export D="$HOME/data/downloads"

is_mac && alias ls="ls -lG"
is_linux && alias ls="ls -l --color"

# source local aliases for stuff I don't want to push to external git
[[ -e $HOME/.zshrc.aliases.local ]] && source $HOME/.zshrc.aliases.local
