#!/usr/bin/env bash
set -Eeu -o pipefail

# Available short options and long options.
#   -h               (short)
#   --help           (long)
#   --dry-run        (long flag, no argument)
#   --config FILE    (long with required argument)
#   --user | -u USER

SHORT_OPTS="hu:"
LONG_OPTS="help,dry-run,config:,user:"


# Detect macOS and ensure GNU getopt is installed
if [[ "$(uname)" == "Darwin" ]]; then
    # Temporarily disable errexit to capture getopt’s exit code
    set +e
    getopt --test >/dev/null 2>&1
    GETOPT_RC=$?
    set -e

    # GNU getopt exits with code 4 when --test succeeds
    if [[ $GETOPT_RC -ne 4 ]]; then
        echo "GNU getopt is required. Installing via Homebrew..." >&2
        if ! command -v brew >/dev/null; then
            echo "Error: Homebrew is not installed. Please install Homebrew first." >&2
            exit 1
        fi
        brew install gnu-getopt && {
			echo "Add gnu getopt into your PATH. Edit ~/.zsh/rc/env.rc and add this if it does not exist:"
			echo 'if [ -d "/opt/homebrew/opt/gnu-getopt/bin" ] && export PATH="/opt/homebrew/opt/gnu-getopt/bin:$PATH"'
			echo "And do a simple export here to update the current shell."
			exit 1
		} || {
            echo "Error: Failed to install gnu-getopt." >&2
            exit 1
        }
    fi

    # Prepend the GNU-getopt bin directory to PATH
    if [[ -d "$(brew --prefix gnu-getopt)/bin" ]]; then
        export PATH="$(brew --prefix gnu-getopt)/bin:$PATH"
    fi
fi


# Run GNU getopt. If it errors out (invalid flags), exit with code 2.
PARSED=$(getopt --options="$SHORT_OPTS" --longoptions="$LONG_OPTS" --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    # getopt complained about invalid options
    exit 2
fi

# Re-set the positional parameters to the output of getopt (all options normalized/ordered).
eval set -- "$PARSED"

# Default values
HELP=0
DRY_RUN=0
ZSH_HOME="$HOME/.zsh"
CONFIG_FILE=""
USER=""

# Process all flags until “--” (end of options)
while true; do
    case "$1" in
        -h|--help)
            HELP=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --config)
            # Next argument ($2) is the FILE for --config
            CONFIG_FILE="$2"
            if [[ -z "$CONFIG_FILE" ]]; then
                echo "Error: --config requires a file argument." >&2
                exit 1
            fi
            shift 2
            ;;
        -u|--user)
            USER="$2"
            if [[ -z "$USER" ]]; then
                echo "Error: --user requires an argument." >&2
                exit 1
            fi
            shift 2
            ;;
        --)
            # End of option parsing
            shift
            break
            ;;
        *)
            echo "Internal error: unexpected option '$1'" >&2
            exit 3
            ;;
    esac
done

# If help was requested, print usage and exit
if [[ $HELP -eq 1 ]]; then
    cat <<EOF
Usage: $0 HOSTNAME|localhost [--dry-run] [--config FILE] [--user USER]

Arguments:
  HOSTNAME           the host you want to operate on - if localhost, it will operate on this very machine

Options:
  -h, --help           show this help message and exit
      --dry-run        do a trial run without making any changes
      --config FILE    read settings from FILE instead of the default
      --user -u USER   run as USER
EOF
    exit 0
fi

# At this point, "$@" contains only the positional args.
if [[ $# -lt 1 ]]; then
    echo "Error: HOSTNAME is required." >&2
    echo "Try '$0 --help' for more information." >&2
    exit 1
fi

HOSTNAME=$1

# Example: show what we have
echo "HOSTNAME    = $HOSTNAME"
echo "DRY_RUN     = $DRY_RUN"
echo "CONFIG_FILE = $CONFIG_FILE"
echo "USER        = $USER"

# install ansible if not present
which ansible-playbook &>/dev/null
if [ $? -eq 1 ]; then
	echo "Ansible is missing, trying to install"
	pip install "ansible<2.14"
fi


CONFIG_FILE_DEFAULT="$ZSH_HOME/ansible/copy_elsewhere.yaml"
OPTIONS=""
if [[ "$HOSTNAME" = "localhost" ]];then
    OPTIONS+=" -c local -K "
    CONFIG_FILE_DEFAULT="$ZSH_HOME/ansible/install_here.yaml"
fi

if [[ "$CONFIG_FILE" = "" ]]; then
    CONFIG_FILE="$CONFIG_FILE_DEFAULT"
fi

if [[ -n "$CONFIG_FILE" ]]; then
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: config file '$CONFIG_FILE' not found." >&2
        exit 1
    fi
    echo "Loading settings from '$CONFIG_FILE'..."
    # source "$CONFIG_FILE"   # or however you want to use it
fi

if [[ "$USER" != "" ]]; then
    HOSTNAME="$USER@$HOSTNAME"
fi

if [[ $DRY_RUN -eq 1 ]]; then
    echo "Running in dry-run mode"
	ansible-playbook $OPTIONS \
		-i "$HOSTNAME," \
		"$CONFIG_FILE" \
		--check
else
    echo "Performing real changes on ${HOSTNAME}"
	ansible-playbook $OPTIONS \
		-i "$HOSTNAME," \
		"$CONFIG_FILE" 
fi