#!/bin/bash
set -Eeu -o pipefail

# install this zsh config package for root

print_help()
{
    script=$(basename $0)
    echo "$script [--dry-run]"
    echo "run as root"
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

get_root_home()
{
    sudo "pwd"
}

DRY_RUN=''

SOURCE_ZSH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
ROOT_HOME=$(echo ~root)


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

if [[ $UID -ne 0 ]]; then
    echo "run as root"
    exit 1
fi

if [[ ! -f "$SOURCE_ZSH/.installed" ]]; then
    echo "You have to install this zsh config for your normal user"
    exit 0
fi

run rsync -a -delete $SOURCE_ZSH $ROOT_HOME/
[[ -f "$ROOT_HOME/.zshrc" ]] && mv $ROOT_HOME/.zshrc $ROOT_HOME/.zshrc.backup
chown -R root:wheel $ROOT_HOME/.zsh
ln -s $ROOT_HOME/.zsh/zshrc $ROOT_HOME/.zshrc  


echo "Installing tmux.conf"
if [[ -f  "$HOME/.tmux.conf" ]]; then
    echo ".tmux.conf already exists. Add the content manually from ~/.zsh/tmux.conf"
else
    ln -s "$HOME/.zsh/tmux.conf" "$HOME/.tmux.conf"
fi
echo

chsh -s /bin/zsh

