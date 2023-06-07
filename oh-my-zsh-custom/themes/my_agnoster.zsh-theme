# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](https://iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# If using with "light" variant of the Solarized color schema, set
# SOLARIZED_THEME variable to "light". If you don't specify, we'll assume
# you're using the "dark" variant.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='DEFAULT'

case ${SOLARIZED_THEME:-dark} in
    light) CURRENT_FG='white';;
    *)     CURRENT_FG='black';;
esac

ROOT_STATUS_FG=yellow
ROOT_STATUS_BG=red

# How many seconds can a comand run before we show its duration in the prompt
MAX_DURATION_SECONDS_BEFORE_PROMPT_STATUS=5

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
}

# print current time in seconds
current_time()
{
  date +%s
}

# variable to track the runtime of the last command
ZSH_AGNOSTER_PREEXEC_TIMER=$(current_time)
# A lock file to ensure that we count the duration of the last command just once.
# This is a little hack, because while we can set variables in preexec(),
# we cannot really change them once inside of prompt rendering. So we cannot stop the counting
# once triggered - the scope will just mask any change, and the next prompt will still see the
# the timer running. 
# The only way I found is to have an externality, like a tempfile.
ZSH_AGNOSTER_PREEXEC_TIMER_LOCK=$(mktemp /tmp/compare.XXXXXX)

# run just before the next command is run
preexec() {
  # save the current time
  ZSH_AGNOSTER_PREEXEC_TIMER=$(current_time)
  # overwrite the prompt time with current one
  current_formatted_time=$(date +"%H:%M:%S")
  echo -e "\033[1A\033[0C$bg[black]${current_formatted_time}"
  touch $ZSH_AGNOSTER_PREEXEC_TIMER_LOCK
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'DEFAULT' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  # you can declare those in before_zsh.rc
  [[ -z $PROMPT_CONTEXT_FG_COLOR ]] && PROMPT_CONTEXT_FG_COLOR=default
  [[ -z $PROMPT_CONTEXT_BG_COLOR ]] && PROMPT_CONTEXT_BG_COLOR=black
  [[ -z $PROMPT_CONTEXT_STRING ]] && PROMPT_CONTEXT_STRING="%n@%m"

  if [[ $UID -eq 0 ]]; then
    PROMPT_CONTEXT_FG_COLOR=$ROOT_STATUS_FG
    PROMPT_CONTEXT_BG_COLOR=$ROOT_STATUS_BG
  fi

  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment $PROMPT_CONTEXT_BG_COLOR $PROMPT_CONTEXT_FG_COLOR $PROMPT_CONTEXT_STRING
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path

   if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]]; then
    repo_path=$(git rev-parse --git-dir 2>/dev/null)
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green $CURRENT_FG
    fi

    local ahead behind
    ahead=$(git log --oneline @{upstream}.. 2>/dev/null | wc -l | xargs) # xargs is used to trim all whitespaces
    behind=$(git log --oneline ..@{upstream} 2>/dev/null | wc -l | xargs)
    if [[ "$ahead" -ne 0 ]] && [[ "$behind" -ne 0 ]]; then
      #PL_BRANCH_CHAR=$'\u21c5'
      PL_BRANCH_CHAR="\u21b1$ahead \u21b0$behind"
    elif [[ "$ahead" -ne 0 ]]; then
      PL_BRANCH_CHAR=$'\u21b1'$ahead
    elif [[ "$behind" -ne 0 ]]; then
      PL_BRANCH_CHAR=$'\u21b0'$behind
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    local stashed_prompt stashed_number
    stashed_number=$(command git stash list 2>/dev/null | wc -l | tr -d ' ')
    if [[ "${stashed_number}" -gt 0 ]]; then
      stashed_prompt="\u2b13"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '±'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'

    vcs_info
    echo -n "${${ref:gs/%/%%}/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${stashed_prompt}${mode}"
  fi
}

prompt_bzr() {
  (( $+commands[bzr] )) || return

  # Test if bzr repository in directory hierarchy
  local dir="$PWD"
  while [[ ! -d "$dir/.bzr" ]]; do
    [[ "$dir" = "/" ]] && return
    dir="${dir:h}"
  done

  local bzr_status status_mod status_all revision
  if bzr_status=$(bzr status 2>&1); then
    status_mod=$(echo -n "$bzr_status" | head -n1 | grep "modified" | wc -m)
    status_all=$(echo -n "$bzr_status" | head -n1 | wc -m)
    revision=${$(bzr log -r-1 --log-format line | cut -d: -f1):gs/%/%%}
    if [[ $status_mod -gt 0 ]] ; then
      prompt_segment yellow black "bzr@$revision ✚"
    else
      if [[ $status_all -gt 0 ]] ; then
        prompt_segment yellow black "bzr@$revision"
      else
        prompt_segment green black "bzr@$revision"
      fi
    fi
  fi
}

prompt_hg() {
  (( $+commands[hg] )) || return
  local rev st branch
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green $CURRENT_FG
      fi
      echo -n ${$(hg prompt "☿ {rev}@{branch}"):gs/%/%%} $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green $CURRENT_FG
      fi
      echo -n "☿ ${rev:gs/%/%%}@${branch:gs/%/%%}" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  #local color_background=blue
  #local color_foreground=$CURRENT_FG
  #if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
  #  color_background='blue'
  #  color_foreground='default'
  #fi
  #prompt_segment $color_background $color_foreground '%~'
  prompt_segment blue $CURRENT_FG '%~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  if [[ -n "$VIRTUAL_ENV" && -n "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
    prompt_segment blue black "(${VIRTUAL_ENV:t:gs/%/%%})"
  fi
}

# Status:
# - was there an error
# - are there background jobs?
prompt_status() {
  local -a symbols
  local delimiter

  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘$RETVAL"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}\U26A1"

  local status_result private_status_file
  private_status_file="$MAIN_ZSH/private/agnoster_private_status.zsh"
  if [[ -f "$private_status_file" ]]; then
    status_result=$($private_status_file)
  fi

  [[  -n "$symbols" &&  -n "$status_result" ]] && delimiter=" "
  [[ -n "$symbols" ||  -n "$status_result" ]] && prompt_segment 235 white "$symbols$delimiter$status_result"
}

#AWS Profile:
# - display current AWS_PROFILE name
# - displays yellow on red if profile name contains 'production' or
#   ends in '-prod'
# - displays black on green otherwise
prompt_aws() {
  [[ -z "$AWS_PROFILE" || "$SHOW_AWS_PROMPT" = false ]] && return
  case "$AWS_PROFILE" in
    *-prod|*production*) prompt_segment red yellow  "AWS: ${AWS_PROFILE:gs/%/%%}" ;;
    *) prompt_segment green black "AWS: ${AWS_PROFILE:gs/%/%%}" ;;
  esac
}

# Time of the prompt render
prompt_time()
{
  local duration_str duration

  if [[ -f "$ZSH_AGNOSTER_PREEXEC_TIMER_LOCK" ]]; then
    duration=$(($(current_time) - $ZSH_AGNOSTER_PREEXEC_TIMER))
    if [[ $duration -gt $MAX_DURATION_SECONDS_BEFORE_PROMPT_STATUS ]]; then
      duration_str=" (${duration}s)"
    fi

    rm $ZSH_AGNOSTER_PREEXEC_TIMER_LOCK
  fi

  prompt_segment black default "%D{%H:%M:%S}$duration_str"
}


## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_time # must be first, or we won't be able to overwrite it in preexec
  prompt_status
  prompt_virtualenv
  prompt_aws
  prompt_context
  prompt_dir
  prompt_git
  prompt_bzr
  prompt_hg
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
