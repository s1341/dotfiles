#!/bin/bash

function realpath {
    pushd $(dirname $1) > /dev/null
    local res=$(pwd)
    popd > /dev/null
    echo "$res/$1"
}

function install_file {
    local source="$1"
    local target="$2"
    echo install_file $source $target
    if [[ -e $target ]]
    then
        if [[ -L $target ]]
        then
            rm $target
        else
            mv $target $target.$(date +'%Y%m%d_%H%M');
        fi
    fi
    ln -s $(realpath $source) $target
}


# switch to the directory of this script
pushd $(dirname $0) > /dev/null

# install vimrc files, meant to be used with spf13
for file in *vimrc*
do
    install_file $file "$HOME/.$file"
done

# install spf13 vim distribution as base, the bundles specified
# in the vimrc.bundles.local file will automatically be installed
curl https://j.mp/spf13-vim3 -L -o - | sh

# build native for YouCompleteMe and vimproc
(cd $HOME/.vim/bundle/vimproc; make clean all)
(cd $HOME/.vim/bundle/YouCompleteMe; ./install.sh --clang-completer --system-libclang)

# install Xdefaults
install_file Xdefaults "$HOME/.Xdefaults"

# install ssh config
install_file ssh_config "$HOME/.ssh/config"

# xmonad
[[ -d $HOME/.xmonad ]] || mkdir -p $HOME/.xmonad
install_file xmonad.hs "$HOME/.xmonad/xmonad.hs"

# we're done, go back to the original directory
popd > /dev/null
