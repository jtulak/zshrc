#!/bin/bash
set -Eeu -o pipefail

# install this zsh config package for the local user

print_help()
{
    script=$(basename $0)
    echo "$script [--dry-run]"
}

# print the command to be run and execute it (unless we are in dry run)
run()
{
    echo $@
    if [[ -n $DRY_RUN ]]; then
        return
    fi
    $@
}
DRY_RUN=''
PWD=$(pwd)
ZSH_BIN=/bin/zsh
USER=$(whoami)

echo "current dir is: $PWD"
echo "home dir is: $HOME"

if [[ "$#" -ne 0 ]]; then
    if [[ "$1" = "--dry-run" ]]; then
        DRY_RUN="true"
    elif [[ "$1" = "-h"  || "$1" = "--help" ]]; then
        print_help
        exit 0
    else
        print_help
        exit 1
    fi
fi

if [[ ! -f "$ZSH_BIN" ]]; then
    echo "zsh itself is not installed"
    exit 1
fi

if [[ -f "$HOME/.zsh/.installed" ]]; then
    echo "already installed"
    exit 0
fi

if [[ ! -d "$HOME/.zsh" ]]; then
    echo "~/.zsh not found, abort!"
    exit 1
fi

if [[ -n $DRY_RUN ]]; then
    echo "Doing dry run, no changes will be applied."
fi
echo

# start installation

# install fonts 
echo "Install fonts..."
if [[ -f "$HOME/.zsh/.installed_fonts" ]]; then
    echo "fonts already installed, skipping"
else
    run cd $HOME/.zsh/dependencies/powerline-fonts
    run ./install.sh
    run cd "$PWD"
    run touch "$HOME/.zsh/.installed_fonts"
fi
echo

# install new .zshrc
echo "Install zshrc..."
if [[ -f "$HOME/.zshrc" ]]; then
    run mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
run ln -s "$HOME/.zsh/zshrc" "$HOME/.zshrc"
echo

# install gitconfig
echo "Install gitconfig..."
if [[ -f  "$HOME/.gitconfig" ]]; then
    echo ".gitconfig already ignores, skipping..."
    echo "If you want to use the bundled one, add this to your gitconfig:"
    echo "[include]"
	echo "path = ~/.zsh/rc/gitconfig"
else
    run eval 'echo -e "[include]\npath = ~/.zsh/rc/gitconfig" > "$HOME/.gitconfig"'
fi
echo

echo "change shell..."
run sudo chsh -s "$ZSH_BIN" $USER
run touch "$HOME/.zsh/.installed" 
echo 

echo "Everything done."
echo "If you are using iterm2, you can configure it to use .zsh/custom_solarized.itermcolors theme."

exit 0


