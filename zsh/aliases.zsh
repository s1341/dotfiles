is_mac || alias rm="rm --one-file-system"

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

sshclean () {
    sed -i "/$1/d" ~/.ssh/known_hosts
}

g13conf () {
    killall Linux-G13-Driver
    java -jar ~/outside_tools/linux-g13-driver-read-only/deploy/Linux-G13_1.0-r44M/Linux-G13-GUI.jar
    nohup ~/outside_tools/linux-g13-driver-read-only/source/Linux-G13-Driver &
}

# cd shortcuts
is_mac && alias cdd="cd $HOME/Downloads" || alias cdd="cd $HOME/data/downloads"
alias cdlh="cd /media/lab/home/srubenst"

export H="$HOME"
export LH="/media/lab/home/srubenst"
export D="$HOME/data/downloads"

is_mac && alias ls="ls -lG"
is_linux && alias ls="ls -l --color"

function pygmentize_cat {
  for arg in "$@"; do
    pygmentize -g "${arg}" 2> /dev/null || /bin/cat "${arg}"
  done
}
command -v pygmentize > /dev/null && alias pcat=pygmentize_cat

# source local aliases for stuff I don't want to push to external git
[[ -e $HOME/.zshrc.aliases.local ]] && source $HOME/.zshrc.aliases.local
