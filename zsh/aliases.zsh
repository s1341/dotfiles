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
    sed -i"bak" "/$1/d" ~/.ssh/known_hosts
}

g13conf () {
    killall Linux-G13-Driver
    java -jar ~/outside_tools/linux-g13-driver-read-only/deploy/Linux-G13_1.0-r44M/Linux-G13-GUI.jar
    nohup ~/outside_tools/linux-g13-driver-read-only/source/Linux-G13-Driver &
}

export H="$HOME"
export LH="/media/lab/home/srubenst"
alias cdlh="cd $LH"
is_mac && export D="$HOME/Downloads" || export D="$HOME/data/downloads"
alias cdd="cd $D"

function cfd () {
  cp $D/$1 .
}

alias dv="dirs -v"

is_mac && alias ls="ls -lG"
is_linux && alias ls="ls -l --color"

function pygmentize_cat {
    for arg in "$@"; do
        pygmentize -g "${arg}" 2> /dev/null || /bin/cat "${arg}"
    done
}
command -v pygmentize_cat > /dev/null && alias pcat=pygmentize_cat

function hdl {
    hexdump -C $@ | less
}

function stringsl {
    strings $@ | less
}

alias ctw="ssh srubenst@10.56.107.214"
function cpfw () {
    scp -r srubenst@10.56.107.214:$1 .
}
function cptw () {
    scp -r $1 srubenst@10.56.107.214:$2
}


# source local aliases for stuff I don't want to push to external git
[[ -e $HOME/.zshrc.aliases.local ]] && source $HOME/.zshrc.aliases.local
