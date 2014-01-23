#!/bin/bash

function realpath {
    pushd $(dirname $1) > /dev/null
    local res=$(pwd)
    popd > /dev/null
    echo "$res/$1"
}

function install_file {
    local args=("$@")
    echo "installfile ${args[@]}"
    local source="${args[0]}"
    local target="${args[1]}"
    local modes="${args[2]}"
    #echo install_file $source $target
    if [[ -e $target ]]
    then
        if [[ -L $target ]]
        then
            rm $target
        else
            mv $target $target.$(date +'%Y%m%d_%H%M');
        fi
    fi
    local realsource=$(realpath $source)
    ln -s $realsource $target
    [[ ! -z $modes ]] && chmod $modes $target

}

echo "[>] starting install"
# switch to the directory of this script
pushd $(dirname $0) > /dev/null
echo "[!] init submodules"
git submodule update --init --recursive

# convert ssh public key to openssl compatible PEM
# we use this PEM to encrypt some sensitive files in a pre-commit hook
if [[ ! -e keys/id_rsa.pem.pub ]]
then
    echo "[*] exporting public key"
    mkdir -p keys
    ssh-keygen -f ~/.ssh/id_rsa.pub -e -m PKCS8 > keys/id_rsa.pub.pem
fi

if [[ ! -e modules/git-crypt/git-crypt ]]
then
    # install git-crypt
    echo "[*] installing git-crypt"
    pushd modules/git-crypt > /dev/null
    make > /dev/null
    chmod +x git-crypt
    popd > /dev/null
fi

# install spf13 vim distribution as base, the bundles specified
# in the vimrc.bundles.local file will automatically be installed
# TODO: don't do the full install every time
echo "[*] spf13"
if [[ ! -h "$HOME/.vim" ]] || [[ `readlink "$HOME/.vim"` != `pwd`/modules/spf13-vim/.vim ]]
then
    echo -e "\t[!] installing spf13"
    pushd "modules/spf13-vim" >/dev/null
    for file in .vim*
    do
        install_file $file "$HOME/$file"
    done
    mkdir -p .vim/bundle >/dev/null
    git clone -v https://github.com/gmarik/vundle.git .vim/bundle/vundle
    popd >/dev/null

    echo -e "\t[*] install local vimrc files"
    for file in *vimrc*
    do
        install_file $file "$HOME/.$file"
    done
    echo -e "\t[*] init bundles"
    vim -u "$HOME/.vimrc.bundles" +BundleInstall! +BundleClean +qall
    echo "[*] build native for YouCompleteMe and vimproc"
    (cd $HOME/.vim/bundle/vimproc; make clean all)
    (cd $HOME/.vim/bundle/YouCompleteMe; ./install.sh --clang-completer --system-libclang)
else
    echo -e "\t[*] update bundles"
    vim +BundleUpdate +BundleClean +qall
fi





echo "[*] install Xdefaults"
install_file Xdefaults "$HOME/.Xdefaults"

echo "[*] install ssh config"
install_file ssh_config "$HOME/.ssh/config" 600

echo "[*] installing xmonad.hs"
[[ -d $HOME/.xmonad ]] || mkdir -p $HOME/.xmonad
install_file xmonad.hs "$HOME/.xmonad/xmonad.hs"

echo "[*] install weechat"
install_file weechat "$HOME/.weechat"

echo "[*] install zsh"
pushd zsh >/dev/null
install_file grmlzshrc "$HOME/.zshrc"
install_file zshrc.local "$HOME/.zshrc.local"
popd >/dev/null


# we're done, go back to the original directory
popd > /dev/null
