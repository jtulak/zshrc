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

# Default separator foreground to use when previous background is 'default'
# Allow override via environment; choose per Solarized theme if unset.
if [[ -z "${AGNOSTER_DEFAULT_SEP_FG}" ]]; then
  case ${SOLARIZED_THEME:-dark} in
    light) AGNOSTER_DEFAULT_SEP_FG='white' ;;
    *)     AGNOSTER_DEFAULT_SEP_FG='black' ;;
  esac
fi

# How many seconds can a comand run before we show its duration in the prompt
MAX_DURATION_SECONDS_BEFORE_PROMPT_STATUS=5

# Special Powerline characters (with ASCII fallback)
()
{
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  if [[ "${POWERLINE_CAPABLE}" == "true" ]]; then
    SEGMENT_SEPARATOR=$'\ue0b0'  # Powerline separator
  else
    SEGMENT_SEPARATOR="${PROMPT_ASCII_SEPARATOR:->}"  # ASCII fallback
  fi
}

# Pick color token depending on color capability
# Usage: _prompt_pick prefer256 fallback16
# - If PROMPT_COLOR_MODE is truecolor or 256 → prefer256 is returned (e.g., 235)
# - Else → fallback16 is returned (e.g., black)
_prompt_pick()
{
  local prefer256="$1" fallback16="$2"
  case "${PROMPT_COLOR_MODE:-}" in
    truecolor|256) print -n -- "$prefer256" ;;
    *)              print -n -- "$fallback16" ;;
  esac
}

# print current time in seconds
current_time()
{
  date +%s
}

# variable to track the runtime of the last command
ZSH_AGNOSTER_PREEXEC_TIMER=$(current_time)
typeset -gi _AGNOSTER_EDIT_BUFFER_LINES=0
# A lock file to ensure that we count the duration of the last command just once.
# This is a little hack, because while we can set variables in preexec(),
# we cannot really change them once inside of prompt rendering. So we cannot stop the counting
# once triggered - the scope will just mask any change, and the next prompt will still see the
# the timer running. 
# The only way I found is to have an externality, like a tempfile.
ZSH_AGNOSTER_PREEXEC_TIMER_LOCK=$(mktemp /tmp/compare.XXXXXX)

# run just before the next command is run
preexec() {
  # Run this only in interactive TTY contexts.
  if [[ "${INTERACTIVE}" != "yes" || ! -t 1 ]]; then
    return
  fi

  # Save the command start time for duration reporting.
  ZSH_AGNOSTER_PREEXEC_TIMER=$(current_time)

  # preexec is the first point where Zsh has accepted the complete command.
  # ZLE records the displayed rows across PS1 and any PS2 continuations so the
  # timestamp can be updated without guessing from the command text.
  local prompt_lines=$_AGNOSTER_EDIT_BUFFER_LINES
  if (( prompt_lines > 0 && prompt_lines < ${LINES:-999999} )); then
    local current_formatted_time=$(date +"%H:%M:%S")
    printf '\0337\033[%dA\r\033[1C' "$prompt_lines"
    print -nP -- "%K{$COLOR_TIME_BG}%F{$COLOR_TIME_FG}${current_formatted_time}%f%k"
    printf '\0338'
  fi

  touch "$ZSH_AGNOSTER_PREEXEC_TIMER_LOCK"
}

# A continued command is read through multiple ZLE sessions: one under PS1 and
# one for each PS2 line. BUFFERLINES includes visual wrapping, so accumulating
# it gives preexec the terminal-row distance back to the original timestamp.
_agnoster_track_prompt_lines_on_line_init() {
  [[ $CONTEXT == start ]] && _AGNOSTER_EDIT_BUFFER_LINES=0
}

_agnoster_track_prompt_lines_on_line_finish() {
  (( _AGNOSTER_EDIT_BUFFER_LINES += BUFFERLINES ))
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  # Usage: prompt_segment <bg> <fg> <content> [sep_fg]
  # - bg/fg may be 'default' to use terminal defaults
  # - sep_fg is used for the triangle separator when previous bg is 'default'
  local bg fg sep_fg join_fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  sep_fg="$4"
  if [[ "${POWERLINE_CAPABLE}" == "true" ]]; then
    if [[ $CURRENT_BG != 'DEFAULT' && $1 != $CURRENT_BG ]]; then
      join_fg="$CURRENT_BG"
      if [[ "$CURRENT_BG" == 'default' || "$CURRENT_BG" == 'DEFAULT' ]]; then
        if [[ -n "$sep_fg" ]]; then
          join_fg="$sep_fg"
        else
          join_fg="$AGNOSTER_DEFAULT_SEP_FG"
        fi
      fi
      echo -n " %{$bg%F{$join_fg}%}$SEGMENT_SEPARATOR%{$fg%} "
    else
      echo -n "%{$bg%}%{$fg%} "
    fi
  else
    # ASCII/compat mode: separate segments with a simple delimiter and avoid
    # rendering the triangle join, but keep bg/fg coloring.
    if [[ $CURRENT_BG != 'DEFAULT' ]]; then
      echo -n " $SEGMENT_SEPARATOR "
    fi
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
  return 0
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ "${POWERLINE_CAPABLE}" == "true" ]]; then
    if [[ -n $CURRENT_BG ]]; then
      local end_fg="$CURRENT_BG"
      if [[ "$CURRENT_BG" == 'default' || "$CURRENT_BG" == 'DEFAULT' ]]; then
        end_fg="$AGNOSTER_DEFAULT_SEP_FG"
      fi
      echo -n " %{%k%F{$end_fg}%}$SEGMENT_SEPARATOR"
    else
      echo -n "%{%k%}"
    fi
  else
    # In compat mode, just reset colors; no trailing separator.
    echo -n " %{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG='DEFAULT'
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  # you can declare those in before_zsh.rc
  [[ -z $PROMPT_CONTEXT_FG_COLOR ]] && PROMPT_CONTEXT_FG_COLOR=$COLOR_CONTEXT_FG
  [[ -z $PROMPT_CONTEXT_BG_COLOR ]] && PROMPT_CONTEXT_BG_COLOR=$COLOR_CONTEXT_BG
  [[ -z $PROMPT_CONTEXT_STRING ]] && PROMPT_CONTEXT_STRING="%n@%m"

  if [[ $UID -eq 0 ]]; then
    PROMPT_CONTEXT_FG_COLOR=$COLOR_CONTEXT_ROOT_FG
    PROMPT_CONTEXT_BG_COLOR=$COLOR_CONTEXT_ROOT_BG
  fi

  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment $PROMPT_CONTEXT_BG_COLOR $PROMPT_CONTEXT_FG_COLOR $PROMPT_CONTEXT_STRING
  fi
}

# Branch and tracked Git state are refreshed synchronously once per prompt;
# untracked presence can be updated asynchronously. Keeping this state outside
# the prompt command substitution is important: $(build_prompt) runs in a
# subshell, so in-memory caches and callbacks could not otherwise persist.
if (( $+builtins[zmodload] )); then
  zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null || :
  zmodload zsh/system 2>/dev/null || :
fi

if [[ -z $AGNOSTER_GIT_REMOTE_CACHE_TTL ]]; then
  AGNOSTER_GIT_REMOTE_CACHE_TTL=5
fi
if [[ -z $AGNOSTER_GIT_UNTRACKED_CACHE_TTL ]]; then
  AGNOSTER_GIT_UNTRACKED_CACHE_TTL=5
fi
typeset -g _AGNOSTER_GIT_REPO=false
typeset -g _AGNOSTER_GIT_BRANCH=""
typeset -g _AGNOSTER_GIT_OID=""
typeset -g _AGNOSTER_GIT_SHORT_OID=""
typeset -g _AGNOSTER_GIT_DETACHED=false
typeset -g _AGNOSTER_GIT_UPSTREAM=""
typeset -g _AGNOSTER_GIT_STAGED=false
typeset -g _AGNOSTER_GIT_UNSTAGED=false
typeset -g _AGNOSTER_GIT_UNTRACKED=false
typeset -g _AGNOSTER_GIT_DIRTY=false
typeset -g _AGNOSTER_GIT_STASHED=false
typeset -g _AGNOSTER_GIT_MODE=""
typeset -g _AGNOSTER_GIT_DIR=""
typeset -g _AGNOSTER_GIT_REMOTE_AHEAD=""
typeset -g _AGNOSTER_GIT_REMOTE_BEHIND=""
typeset -g _AGNOSTER_GIT_REMOTE_CACHE_KEY=""
typeset -g _AGNOSTER_GIT_REMOTE_CACHE_OID=""
typeset -g _AGNOSTER_GIT_REMOTE_CACHE_AHEAD=""
typeset -g _AGNOSTER_GIT_REMOTE_CACHE_BEHIND=""
typeset -g _AGNOSTER_GIT_REMOTE_CACHE_TIME=0
if (( ${+functions[_agnoster_git_untracked_cleanup]} )); then
  _agnoster_git_untracked_cleanup
fi
typeset -gA _AGNOSTER_GIT_UNTRACKED_CACHE=()
typeset -gA _AGNOSTER_GIT_UNTRACKED_CACHE_TIME=()
typeset -g _AGNOSTER_GIT_UNTRACKED_PENDING_KEY=""
typeset -gi _AGNOSTER_GIT_UNTRACKED_PENDING_GENERATION=0
typeset -gi _AGNOSTER_GIT_UNTRACKED_FD=-1
typeset -gi _AGNOSTER_GIT_UNTRACKED_PID=-1
typeset -gi _AGNOSTER_GIT_COMMAND_GENERATION=0
typeset -g _AGNOSTER_GIT_COMMAND_RAN=false
typeset -g _AGNOSTER_LAST_STATUS=0

_agnoster_git_reset_state() {
  _AGNOSTER_GIT_REPO=false
  _AGNOSTER_GIT_BRANCH=""
  _AGNOSTER_GIT_OID=""
  _AGNOSTER_GIT_SHORT_OID=""
  _AGNOSTER_GIT_DETACHED=false
  _AGNOSTER_GIT_UPSTREAM=""
  _AGNOSTER_GIT_STAGED=false
  _AGNOSTER_GIT_UNSTAGED=false
  _AGNOSTER_GIT_UNTRACKED=false
  _AGNOSTER_GIT_DIRTY=false
  _AGNOSTER_GIT_STASHED=false
  _AGNOSTER_GIT_MODE=""
  _AGNOSTER_GIT_DIR=""
  _AGNOSTER_GIT_REMOTE_AHEAD=""
  _AGNOSTER_GIT_REMOTE_BEHIND=""
}

_agnoster_git_now() {
  if (( $+parameters[EPOCHSECONDS] )); then
    REPLY=$EPOCHSECONDS
  else
    REPLY=$(date +%s)
  fi
}

_agnoster_git_clear_remote_cache() {
  _AGNOSTER_GIT_REMOTE_CACHE_KEY=""
  _AGNOSTER_GIT_REMOTE_CACHE_OID=""
  _AGNOSTER_GIT_REMOTE_CACHE_AHEAD=""
  _AGNOSTER_GIT_REMOTE_CACHE_BEHIND=""
  _AGNOSTER_GIT_REMOTE_CACHE_TIME=0
}

_agnoster_git_refresh_remote() {
  local ttl=$AGNOSTER_GIT_REMOTE_CACHE_TTL
  [[ $ttl == <-> ]] || ttl=5

  _AGNOSTER_GIT_REMOTE_AHEAD=""
  _AGNOSTER_GIT_REMOTE_BEHIND=""
  if [[ -z $_AGNOSTER_GIT_UPSTREAM || $_AGNOSTER_GIT_OID == '(initial)' ]]; then
    _agnoster_git_clear_remote_cache
    return 0
  fi

  local cache_key="$_AGNOSTER_GIT_DIR|$_AGNOSTER_GIT_BRANCH|$_AGNOSTER_GIT_UPSTREAM"
  _agnoster_git_now
  local now=$REPLY
  if [[ $cache_key == $_AGNOSTER_GIT_REMOTE_CACHE_KEY &&
        $_AGNOSTER_GIT_OID == $_AGNOSTER_GIT_REMOTE_CACHE_OID &&
        $ttl -gt 0 && $now -ge $_AGNOSTER_GIT_REMOTE_CACHE_TIME &&
        $(( now - _AGNOSTER_GIT_REMOTE_CACHE_TIME )) -lt $ttl ]]; then
    _AGNOSTER_GIT_REMOTE_AHEAD=$_AGNOSTER_GIT_REMOTE_CACHE_AHEAD
    _AGNOSTER_GIT_REMOTE_BEHIND=$_AGNOSTER_GIT_REMOTE_CACHE_BEHIND
    return
  fi

  local counts
  if counts=$(__git_prompt_git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null); then
    local -a count_parts
    count_parts=(${=counts})
    if (( ${#count_parts} == 2 )) && [[ $count_parts[1] == <-> && $count_parts[2] == <-> ]]; then
      _AGNOSTER_GIT_REMOTE_AHEAD=$count_parts[1]
      _AGNOSTER_GIT_REMOTE_BEHIND=$count_parts[2]
      _AGNOSTER_GIT_REMOTE_CACHE_KEY=$cache_key
      _AGNOSTER_GIT_REMOTE_CACHE_OID=$_AGNOSTER_GIT_OID
      _AGNOSTER_GIT_REMOTE_CACHE_AHEAD=$_AGNOSTER_GIT_REMOTE_AHEAD
      _AGNOSTER_GIT_REMOTE_CACHE_BEHIND=$_AGNOSTER_GIT_REMOTE_BEHIND
      _AGNOSTER_GIT_REMOTE_CACHE_TIME=$now
    else
      _agnoster_git_clear_remote_cache
    fi
  else
    _agnoster_git_clear_remote_cache
  fi
}

_agnoster_git_untracked_probe() {
  emulate -L zsh
  local worktree=$1
  local -a status_args pipe_status
  status_args=(status --porcelain=v1 --untracked-files=normal)
  case ${GIT_STATUS_IGNORE_SUBMODULES:-} in
    git) ;;
    *) status_args+=(--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}) ;;
  esac

  GIT_OPTIONAL_LOCKS=0 command git -C "$worktree" $status_args 2>/dev/null |
    command grep -q '^?? '
  pipe_status=($pipestatus)
  if (( pipe_status[2] == 0 )); then
    print -r -- true
  elif (( pipe_status[1] == 0 )); then
    print -r -- false
  else
    print -r -- error
  fi
}

_agnoster_git_apply_untracked_cache() {
  local cached=${_AGNOSTER_GIT_UNTRACKED_CACHE[$_AGNOSTER_GIT_DIR]-}
  if [[ $cached == true || $cached == false ]]; then
    _AGNOSTER_GIT_UNTRACKED=$cached
  fi
}

_agnoster_git_zle() {
  zle "$@"
}

_agnoster_git_start_untracked_refresh() {
  [[ $DISABLE_UNTRACKED_FILES_DIRTY == true ]] || return 0
  [[ $_AGNOSTER_GIT_REPO == true && -n $_AGNOSTER_GIT_DIR ]] || return 0
  (( _AGNOSTER_GIT_UNTRACKED_FD == -1 )) || return 0
  [[ -o interactive && -t 0 && -t 1 ]] || return 0
  (( $+builtins[zle] && $+parameters[sysparams] )) || return 0

  local key=$_AGNOSTER_GIT_DIR
  local generation=$_AGNOSTER_GIT_COMMAND_GENERATION
  local worktree=$PWD
  local fd worker_pid
  exec {fd}< <(
    print -r -- $sysparams[pid]
    _agnoster_git_untracked_probe "$worktree"
  ) || return 0

  if ! IFS= read -r -u $fd worker_pid; then
    exec {fd}<&-
    return 0
  fi

  _AGNOSTER_GIT_UNTRACKED_FD=$fd
  _AGNOSTER_GIT_UNTRACKED_PID=$worker_pid
  _AGNOSTER_GIT_UNTRACKED_PENDING_KEY=$key
  _AGNOSTER_GIT_UNTRACKED_PENDING_GENERATION=$generation
  if ! _agnoster_git_zle -F $fd _agnoster_git_untracked_callback 2>/dev/null; then
    exec {fd}<&-
    _AGNOSTER_GIT_UNTRACKED_FD=-1
    _AGNOSTER_GIT_UNTRACKED_PID=-1
    _AGNOSTER_GIT_UNTRACKED_PENDING_KEY=""
  fi
}

_agnoster_git_schedule_untracked_refresh() {
  [[ $DISABLE_UNTRACKED_FILES_DIRTY == true ]] || return 0
  [[ $_AGNOSTER_GIT_REPO == true && -n $_AGNOSTER_GIT_DIR ]] || return 0
  (( _AGNOSTER_GIT_UNTRACKED_FD == -1 )) || return 0

  local ttl=$AGNOSTER_GIT_UNTRACKED_CACHE_TTL
  [[ $ttl == <-> ]] || ttl=5
  _agnoster_git_now
  local now=$REPLY
  local cached=${_AGNOSTER_GIT_UNTRACKED_CACHE[$_AGNOSTER_GIT_DIR]-}
  local cached_at=${_AGNOSTER_GIT_UNTRACKED_CACHE_TIME[$_AGNOSTER_GIT_DIR]:-0}
  if [[ $_AGNOSTER_GIT_COMMAND_RAN == true || -z $cached || $ttl -eq 0 ||
        $now -lt $cached_at || $(( now - cached_at )) -ge $ttl ]]; then
    _agnoster_git_start_untracked_refresh
  fi
}

_agnoster_git_untracked_callback() {
  emulate -L zsh
  local fd=$1 err=$2 output=""
  local key=$_AGNOSTER_GIT_UNTRACKED_PENDING_KEY
  local generation=$_AGNOSTER_GIT_UNTRACKED_PENDING_GENERATION

  if [[ -z $err || $err == hup ]]; then
    IFS= read -r -u $fd -d '' output || :
    output=${output//$'\n'/}
  fi

  _agnoster_git_zle -F $fd 2>/dev/null || :
  exec {fd}<&-
  _AGNOSTER_GIT_UNTRACKED_FD=-1
  _AGNOSTER_GIT_UNTRACKED_PID=-1
  _AGNOSTER_GIT_UNTRACKED_PENDING_KEY=""

  local stale=false
  if (( generation != _AGNOSTER_GIT_COMMAND_GENERATION )) ||
      [[ $key != $_AGNOSTER_GIT_DIR ]]; then
    stale=true
  fi

  if [[ $output == true || $output == false ]]; then
    _agnoster_git_now
    _AGNOSTER_GIT_UNTRACKED_CACHE[$key]=$output
    _AGNOSTER_GIT_UNTRACKED_CACHE_TIME[$key]=$REPLY
    if [[ $stale == false && $_AGNOSTER_GIT_REPO == true &&
          $DISABLE_UNTRACKED_FILES_DIRTY == true ]]; then
      local previous=$_AGNOSTER_GIT_UNTRACKED
      _AGNOSTER_GIT_UNTRACKED=$output
      if [[ $previous != $output ]]; then
        _agnoster_git_zle .reset-prompt
      fi
    fi
  fi

  if [[ $stale == true && $_AGNOSTER_GIT_REPO == true ]]; then
    _agnoster_git_start_untracked_refresh
  fi
}

_agnoster_git_untracked_cleanup() {
  local fd=$_AGNOSTER_GIT_UNTRACKED_FD
  if (( fd != -1 )); then
    (( $+builtins[zle] )) && _agnoster_git_zle -F $fd 2>/dev/null || :
    exec {fd}<&-
  fi
  if (( _AGNOSTER_GIT_UNTRACKED_PID > 0 )); then
    kill -TERM $_AGNOSTER_GIT_UNTRACKED_PID 2>/dev/null || :
  fi
  _AGNOSTER_GIT_UNTRACKED_FD=-1
  _AGNOSTER_GIT_UNTRACKED_PID=-1
  _AGNOSTER_GIT_UNTRACKED_PENDING_KEY=""
}

_agnoster_git_refresh() {
  _agnoster_git_reset_state
  (( $+commands[git] )) || return 0

  local hide_status
  hide_status=$(__git_prompt_git config --get oh-my-zsh.hide-status 2>/dev/null) || hide_status=''
  [[ $hide_status == 1 ]] && return 0

  local -a status_args
  status_args=(status --porcelain=v2 --branch --show-stash --no-ahead-behind)
  if [[ $DISABLE_UNTRACKED_FILES_DIRTY == true ]]; then
    status_args+=(--untracked-files=no)
  else
    status_args+=(--untracked-files=normal)
  fi
  case ${GIT_STATUS_IGNORE_SUBMODULES:-} in
    git) ;;
    *) status_args+=(--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}) ;;
  esac

  local status_text
  status_text=$(__git_prompt_git $status_args 2>/dev/null) || return 0

  local branch oid upstream hide_dirty
  local staged=false unstaged=false untracked=false stashed=false
  local -a status_lines fields
  status_lines=("${(@f)status_text}")
  local line xy
  for line in "${status_lines[@]}"; do
    case $line in
      '# branch.head '*) branch=${line#\# branch.head } ;;
      '# branch.oid '*) oid=${line#\# branch.oid } ;;
      '# branch.upstream '*) upstream=${line#\# branch.upstream } ;;
      '# stash '*) stashed=true ;;
      '1 '*|'2 '*|'u '*)
        fields=(${=line})
        xy=${fields[2]}
        [[ ${xy[1]} != '.' ]] && staged=true
        [[ ${xy[2]} != '.' ]] && unstaged=true
        ;;
      '? '*) untracked=true ;;
    esac
  done

  _AGNOSTER_GIT_REPO=true
  _AGNOSTER_GIT_BRANCH=$branch
  _AGNOSTER_GIT_OID=$oid
  _AGNOSTER_GIT_UPSTREAM=$upstream
  _AGNOSTER_GIT_STAGED=$staged
  _AGNOSTER_GIT_UNSTAGED=$unstaged
  _AGNOSTER_GIT_UNTRACKED=$untracked
  _AGNOSTER_GIT_STASHED=$stashed
  [[ $branch == '(detached)' ]] && _AGNOSTER_GIT_DETACHED=true

  hide_dirty=$(__git_prompt_git config --get oh-my-zsh.hide-dirty 2>/dev/null) || hide_dirty=''
  if [[ $hide_dirty != 1 ]]; then
    if [[ $staged == true || $unstaged == true ||
          ($untracked == true && $DISABLE_UNTRACKED_FILES_DIRTY != true) ]]; then
      _AGNOSTER_GIT_DIRTY=true
    fi
  fi

  _AGNOSTER_GIT_DIR=$(__git_prompt_git rev-parse --absolute-git-dir 2>/dev/null)
  [[ -n $_AGNOSTER_GIT_DIR ]] || return 0
  _AGNOSTER_GIT_DIR=${_AGNOSTER_GIT_DIR:A}
  if [[ $DISABLE_UNTRACKED_FILES_DIRTY == true ]]; then
    _agnoster_git_apply_untracked_cache
  fi

  if [[ $_AGNOSTER_GIT_DETACHED == true && $_AGNOSTER_GIT_OID != '(initial)' ]]; then
    _AGNOSTER_GIT_SHORT_OID=$(__git_prompt_git rev-parse --short HEAD 2>/dev/null)
    [[ -n $_AGNOSTER_GIT_SHORT_OID ]] || _AGNOSTER_GIT_SHORT_OID=${_AGNOSTER_GIT_OID[1,7]}
  fi

  if [[ -e $_AGNOSTER_GIT_DIR/BISECT_LOG ]]; then
    _AGNOSTER_GIT_MODE=' <B>'
  elif [[ -e $_AGNOSTER_GIT_DIR/MERGE_HEAD ]]; then
    _AGNOSTER_GIT_MODE=' >M<'
  elif [[ -e $_AGNOSTER_GIT_DIR/rebase || -e $_AGNOSTER_GIT_DIR/rebase-apply ||
          -e $_AGNOSTER_GIT_DIR/rebase-merge || -e $_AGNOSTER_GIT_DIR/../.dotest ]]; then
    _AGNOSTER_GIT_MODE=' >R>'
  fi

  _agnoster_git_refresh_remote
}

# Git: branch/detached head, dirty status. Rendering only; refresh work is in
# _agnoster_git_precmd so it runs in the parent shell and can retain its cache.
prompt_git() {
  [[ $_AGNOSTER_GIT_REPO == true ]] || return 0

  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    if [[ "${POWERLINE_CAPABLE}" == "true" ]]; then
      PL_BRANCH_CHAR=$'\ue0a0'       # 
    else
      PL_BRANCH_CHAR='git:'          # ASCII fallback
    fi
  }

  if [[ $_AGNOSTER_GIT_DIRTY == true ]]; then
    prompt_segment $COLOR_GIT_DIRTY_BG $COLOR_GIT_DIRTY_FG
  else
    prompt_segment $COLOR_GIT_CLEAN_BG $COLOR_GIT_CLEAN_FG
  fi

  local ahead=$_AGNOSTER_GIT_REMOTE_AHEAD
  local behind=$_AGNOSTER_GIT_REMOTE_BEHIND
  if [[ -n $ahead && -n $behind ]]; then
    if [[ $POWERLINE_CAPABLE == true ]]; then
      if (( ahead != 0 )) && (( behind != 0 )); then
        PL_BRANCH_CHAR="\u21b1$ahead \u21b0$behind"
      elif (( ahead != 0 )); then
        PL_BRANCH_CHAR=$'\u21b1'$ahead
      elif (( behind != 0 )); then
        PL_BRANCH_CHAR=$'\u21b0'$behind
      fi
    else
      if (( ahead != 0 )) && (( behind != 0 )); then
        PL_BRANCH_CHAR="^$ahead v$behind"
      elif (( ahead != 0 )); then
        PL_BRANCH_CHAR="^$ahead"
      elif (( behind != 0 )); then
        PL_BRANCH_CHAR="v$behind"
      fi
    fi
  fi

  local ref
  if [[ $_AGNOSTER_GIT_DETACHED == true ]]; then
    ref="➦ $_AGNOSTER_GIT_SHORT_OID"
  else
    ref="refs/heads/$_AGNOSTER_GIT_BRANCH"
  fi

  local vcs_prompt=""
  [[ $_AGNOSTER_GIT_UNSTAGED == true ]] && vcs_prompt+='±'
  [[ $_AGNOSTER_GIT_STAGED == true ]] && vcs_prompt+='✚'
  [[ -n $vcs_prompt ]] && vcs_prompt=" $vcs_prompt"

  local stashed_prompt='' new_files_prompt=''
  if [[ $_AGNOSTER_GIT_STASHED == true ]]; then
    [[ $POWERLINE_CAPABLE == true ]] && stashed_prompt=' \u2b13' || stashed_prompt=' S'
  fi
  [[ $_AGNOSTER_GIT_UNTRACKED == true ]] && new_files_prompt=' ?'

  echo -n "${${ref:gs/%/%%}/refs\/heads\//$PL_BRANCH_CHAR }${vcs_prompt}${stashed_prompt}${new_files_prompt}$_AGNOSTER_GIT_MODE"
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
      prompt_segment $COLOR_GIT_DIRTY_BG $COLOR_GIT_DIRTY_FG "bzr@$revision ✚"
    else
      if [[ $status_all -gt 0 ]] ; then
        prompt_segment $COLOR_GIT_DIRTY_BG $COLOR_GIT_DIRTY_FG "bzr@$revision"
      else
        prompt_segment $COLOR_GIT_CLEAN_BG $COLOR_GIT_CLEAN_FG "bzr@$revision"
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
        prompt_segment $COLOR_GIT_DIRTY_BG $COLOR_GIT_DIRTY_FG
        st='±'
      else
        # if working copy is clean
        prompt_segment $COLOR_GIT_CLEAN_BG $COLOR_GIT_CLEAN_FG
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
        prompt_segment $COLOR_GIT_DIRTY_BG $COLOR_GIT_DIRTY_FG
        st='±'
      else
        prompt_segment $COLOR_GIT_CLEAN_BG $COLOR_GIT_CLEAN_FG
      fi
      echo -n "☿ ${rev:gs/%/%%}@${branch:gs/%/%%}" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment $COLOR_PATH_BG $COLOR_PATH_FG '%~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  if [[ -n "$VIRTUAL_ENV" && -n "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
    #venv_name=$VIRTUAL_ENV
    venv_name="venv"
    prompt_segment $COLOR_VENV_BG $COLOR_VENV_FG "(${venv_name:t:gs/%/%%})"
  fi
}

# Status:
# - was there an error
# - are there background jobs?
prompt_status() {
  local -a symbols
  local delimiter
  local glyphs=${POWERLINE_CAPABLE:-false}

  if [[ $RETVAL -ne 0 ]]; then
    if [[ "$glyphs" == "true" ]]; then
      symbols+="%{%F{${COLOR_STATUS_ERR_FG}}%}✘$RETVAL"
    else
      symbols+="%{%F{${COLOR_STATUS_ERR_FG}}%}x$RETVAL"
    fi
  fi
  if [[ $(jobs -l | wc -l) -gt 0 ]]; then
    if [[ "$glyphs" == "true" ]]; then
      symbols+="%{%F{${COLOR_STATUS_JOBS_FG}}%}⚙"
    else
      symbols+="%{%F{${COLOR_STATUS_JOBS_FG}}%}j"
    fi
  fi
  if [[ $UID -eq 0 ]]; then
    if [[ "$glyphs" == "true" ]]; then
      symbols+="%{%F{${COLOR_STATUS_ROOT_FG}}%}\U26A1"
    else
      symbols+="%{%F{${COLOR_STATUS_ROOT_FG}}%}!"
    fi
  fi

  local status_result private_status_file
  private_status_file="$MAIN_ZSH/private/agnoster_private_status.zsh"
  if [[ -f "$private_status_file" ]]; then
    status_result=$($private_status_file)
  fi

  [[  -n "$symbols" &&  -n "$status_result" ]] && delimiter=" "
  [[ -n "$symbols" ||  -n "$status_result" ]] && prompt_segment $COLOR_STATUS_BG $COLOR_STATUS_FG "$symbols$delimiter$status_result"
}

#AWS Profile:
# - display current AWS_PROFILE name
# - displays yellow on red if profile name contains 'production' or
#   ends in '-prod'
# - displays black on green otherwise
prompt_aws() {
  [[ -z "$AWS_PROFILE" || "$SHOW_AWS_PROMPT" = false ]] && return
  case "$AWS_PROFILE" in
    *-prod|*production*) prompt_segment $COLOR_AWS_PROD_BG $COLOR_AWS_PROD_FG  "AWS: ${AWS_PROFILE:gs/%/%%}" ;;
    *) prompt_segment $COLOR_AWS_NONPROD_BG $COLOR_AWS_NONPROD_FG "AWS: ${AWS_PROFILE:gs/%/%%}" ;;
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
  prompt_segment $COLOR_TIME_BG $COLOR_TIME_FG "%D{%H:%M:%S}$duration_str" "$COLOR_TIME_SEP_FG"
}


_agnoster_git_preexec() {
  (( ++_AGNOSTER_GIT_COMMAND_GENERATION ))
  _AGNOSTER_GIT_COMMAND_RAN=true
  return 0
}

_agnoster_git_precmd() {
  local last_status=$?
  _AGNOSTER_LAST_STATUS=$last_status
  _agnoster_git_refresh
  _agnoster_git_schedule_untracked_refresh
  _AGNOSTER_GIT_COMMAND_RAN=false
  return 0
}

autoload -Uz add-zsh-hook add-zle-hook-widget
typeset -ga precmd_functions
(( ${+precmd_functions} )) || precmd_functions=()
add-zsh-hook -d preexec _agnoster_git_preexec
add-zsh-hook preexec _agnoster_git_preexec
add-zsh-hook -d precmd _agnoster_git_precmd
add-zsh-hook precmd _agnoster_git_precmd
add-zsh-hook -d zshexit _agnoster_git_untracked_cleanup
add-zsh-hook zshexit _agnoster_git_untracked_cleanup
add-zle-hook-widget -d line-init _agnoster_track_prompt_lines_on_line_init
add-zle-hook-widget line-init _agnoster_track_prompt_lines_on_line_init
add-zle-hook-widget -d line-finish _agnoster_track_prompt_lines_on_line_finish
add-zle-hook-widget line-finish _agnoster_track_prompt_lines_on_line_finish
# Capture the command status before other precmd hooks can change it while
# retaining those hooks and their existing order relative to one another.
precmd_functions=(_agnoster_git_precmd ${precmd_functions:#_agnoster_git_precmd})

## Main prompt
build_prompt() {
  RETVAL=$_AGNOSTER_LAST_STATUS
  prompt_time
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
