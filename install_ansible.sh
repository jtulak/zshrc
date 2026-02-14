#!/usr/bin/env bash
set -Eeu -o pipefail

# Available short options and long options.
#   -h               (short)
#   --help           (long)
#   --dry-run        (long flag, no argument)
#   --config FILE    (long with required argument)
#   --user | -u USER
#   --legacy         (use legacy ansible for OL7)
#   --copy-private   (force copy ~/.zsh/private)

SHORT_OPTS="hu:l"
LONG_OPTS="help,dry-run,config:,user:,legacy,copy-private"

set -x

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
USE_LEGACY=0
COPY_PRIVATE=0
declare -a EXTRA_VARS=()

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
        -l|--legacy)
            USE_LEGACY=1
            shift
            ;;
        --copy-private)
            COPY_PRIVATE=1
            shift
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
      --legacy         use legacy ansible for OL7
      --copy-private   force copy ~/.zsh/private
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
echo "LEGACY      = $USE_LEGACY"
echo "COPY_PRIVATE= $COPY_PRIVATE"

# Ensure uvx (UV runner) is present
if ! command -v uvx >/dev/null 2>&1; then
    echo "Error: uvx (UV) is required to run Ansible without a local venv." >&2
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "Install UV via Homebrew: brew install uv" >&2
    else
        echo "Install UV from https://docs.astral.sh/uv/#installation" >&2
    fi
    exit 1
fi

# Determine Ansible package spec (overridable via ANSIBLE_PKG_SPEC)
# Default package selection: follow UV warning for legacy where ansible-playbook
# is provided by ansible-base in the 2.10 era. Allow override via ANSIBLE_PKG_SPEC.
if [[ -z "${ANSIBLE_PKG_SPEC:-}" ]]; then
    if [[ $USE_LEGACY -eq 1 ]]; then
        # Use ansible-base for legacy to avoid uvx warning and match where the console script lives.
        ANSIBLE_LAUNCH=("uvx" "--from" "ansible==2.10.*" "ansible-playbook")
    else
        # Use ansible-core (provides binary) + ansible (provides standard collections) to avoid uvx warning
        ANSIBLE_LAUNCH=("uvx" "--from" "ansible-core" "--with" "ansible" "ansible-playbook")
    fi
else
    # User override - they are responsible for correct flags/specs.
    ANSIBLE_LAUNCH=("uvx" "--from" "${ANSIBLE_PKG_SPEC}" "ansible-playbook")
fi


CONFIG_FILE_DEFAULT="$ZSH_HOME/ansible/install.yaml"
declare -a OPTIONS=()
if [[ "$HOSTNAME" = "localhost" ]];then
    OPTIONS+=(-c local)
fi
OPTIONS+=(-K)

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

if [[ $COPY_PRIVATE -eq 1 ]]; then
    EXTRA_VARS+=(-e "zsh_copy_private=true")
fi
if [[ $DRY_RUN -eq 1 ]]; then
    echo "Running in dry-run mode"
    CMD=("${ANSIBLE_LAUNCH[@]}")
    if (( ${#OPTIONS[@]} )); then
        CMD+=("${OPTIONS[@]}")
    fi
    CMD+=(-i "$HOSTNAME," "$CONFIG_FILE")
    if (( ${#EXTRA_VARS[@]} )); then
        CMD+=("${EXTRA_VARS[@]}")
    fi
    CMD+=(--check)
	"${CMD[@]}"
else
    echo "Performing real changes on ${HOSTNAME}"
    CMD=("${ANSIBLE_LAUNCH[@]}")
    if (( ${#OPTIONS[@]} )); then
        CMD+=("${OPTIONS[@]}")
    fi
    CMD+=(-i "$HOSTNAME," "$CONFIG_FILE")
    if (( ${#EXTRA_VARS[@]} )); then
        CMD+=("${EXTRA_VARS[@]}")
    fi
	"${CMD[@]}"
fi
