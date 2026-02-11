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
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ROOT_HOME=$(echo ~root)


if [[ "$#" -ne 0 ]]; then
    if [[ "$1" = "--dry-run" ]]; then
        DRY_RUN="--dry-run"
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
    #exit 1
fi

$SCRIPT_DIR/install_ansible.sh localhost $DRY_RUN -u root

exit 0
