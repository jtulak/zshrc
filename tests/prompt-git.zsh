#!/usr/bin/env zsh

setopt errexit pipefail

typeset -g MAIN_ZSH=${MAIN_ZSH:-${0:A:h:h}}
typeset -g INTERACTIVE=no
typeset -g POWERLINE_CAPABLE=false
typeset -g DISABLE_UNTRACKED_FILES_DIRTY=true
typeset -g AGNOSTER_GIT_REMOTE_CACHE_TTL=5
typeset -g COLOR_GIT_DIRTY_BG=red COLOR_GIT_DIRTY_FG=white
typeset -g COLOR_GIT_CLEAN_BG=green COLOR_GIT_CLEAN_FG=black
typeset -ga precmd_functions
_test_existing_precmd() { return 0 }
precmd_functions=(_test_existing_precmd)

source "$MAIN_ZSH/dependencies/oh-my-zsh/lib/git.zsh"
source "$MAIN_ZSH/oh-my-zsh-custom/themes/my_agnoster.zsh-theme"

[[ " ${precmd_functions[*]} " == *' _test_existing_precmd '* ]] || {
  print -u2 -r -- 'FAIL: existing precmd hook was not preserved'
  exit 1
}
(( ${precmd_functions[(ie)_agnoster_precmd]} == 1 &&
   ${precmd_functions[(Ie)_agnoster_precmd]} == 1 )) || {
  print -u2 -r -- 'FAIL: prompt precmd hook is missing or duplicated'
  exit 1
}
(( ${preexec_functions[(ie)_agnoster_preexec]} == 1 &&
   ${preexec_functions[(Ie)_agnoster_preexec]} == 1 )) || {
  print -u2 -r -- 'FAIL: prompt preexec hook is missing or duplicated'
  exit 1
}

typeset -g _TEST_FAIL_REMOTE=false
__git_prompt_git() {
  if [[ $1 == rev-list && $_TEST_FAIL_REMOTE == true ]]; then
    return 1
  fi
  GIT_OPTIONAL_LOCKS=0 command git "$@"
}

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

assert_eq() {
  [[ $1 == $2 ]] || fail "$3 (expected '$2', got '$1')"
}

assert_true() {
  [[ $1 == true ]] || fail "$2 (expected true, got '$1')"
}

mk_repo() {
  local repo
  repo=$(mktemp -d "${TMPDIR:-/tmp}/agnoster-prompt.XXXXXX")
  git -C "$repo" init -q
  git -C "$repo" config core.fsmonitor false
  git -C "$repo" config user.email test@example.invalid
  git -C "$repo" config user.name PromptTest
  print -r -- base >| "$repo/file"
  git -C "$repo" add file
  git -C "$repo" commit -qm base
  print -r -- "$repo"
}

root=$(mktemp -d "${TMPDIR:-/tmp}/agnoster-prompt-suite.XXXXXX")
trap 'rm -rf "$root"' EXIT

repo=$(mk_repo)
cd "$repo"
_agnoster_git_refresh
assert_true "$_AGNOSTER_GIT_REPO" clean repository detected
assert_eq "$_AGNOSTER_GIT_DIRTY" false clean repository is clean
assert_eq "$_AGNOSTER_GIT_UNTRACKED" false clean repository has no untracked marker
clean_render=$(prompt_git)
[[ $clean_render == *'%K{green}'* ]] || fail clean repository uses clean background

print -r -- changed >> file
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_UNSTAGED" true unstaged change detected
assert_eq "$_AGNOSTER_GIT_DIRTY" true unstaged change is dirty
dirty_render=$(prompt_git)
[[ $dirty_render == *'%K{red}'* ]] || fail dirty repository uses dirty background

git add file
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_STAGED" true staged change detected
assert_eq "$_AGNOSTER_GIT_UNSTAGED" false staged change is not unstaged

git reset -q HEAD file
git checkout -q -- file
print -r -- new >| untracked-file
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_DIRTY" false DISABLE_UNTRACKED_FILES_DIRTY preserves clean color
assert_eq "$_AGNOSTER_GIT_UNTRACKED" false untracked marker waits for asynchronous result
assert_eq "$(_agnoster_git_untracked_probe "$repo")" true asynchronous probe detects untracked file
_AGNOSTER_GIT_UNTRACKED_CACHE[$_AGNOSTER_GIT_DIR]=true
_AGNOSTER_GIT_UNTRACKED_CACHE_TIME[$_AGNOSTER_GIT_DIR]=$EPOCHSECONDS
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_UNTRACKED" true cached asynchronous marker is rendered
assert_eq "$_AGNOSTER_GIT_DIRTY" false cached untracked marker preserves clean color
DISABLE_UNTRACKED_FILES_DIRTY=false
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_UNTRACKED" true synchronous mode detects untracked file
assert_eq "$_AGNOSTER_GIT_DIRTY" true synchronous untracked mode is dirty
DISABLE_UNTRACKED_FILES_DIRTY=true

git -C "$repo" config oh-my-zsh.hide-dirty 1
print -r -- hidden-dirty >> "$repo/file"
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_DIRTY" false hide-dirty preserves clean background
assert_eq "$_AGNOSTER_GIT_UNSTAGED" true hide-dirty keeps local change marker
git -C "$repo" config --unset oh-my-zsh.hide-dirty

conflict_repo=$(mk_repo)
git -C "$conflict_repo" checkout -qb side
print -r -- side >| "$conflict_repo/file"
git -C "$conflict_repo" add file
git -C "$conflict_repo" commit -qm side
git -C "$conflict_repo" checkout -q master
print -r -- master >| "$conflict_repo/file"
git -C "$conflict_repo" add file
git -C "$conflict_repo" commit -qm master
if git -C "$conflict_repo" merge side >/dev/null 2>&1; then
  fail merge unexpectedly succeeded
fi
cd "$conflict_repo"
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_STAGED" true conflict has staged-side state
assert_eq "$_AGNOSTER_GIT_UNSTAGED" true conflict has worktree-side state
git -C "$conflict_repo" merge --abort

unborn="$root/unborn"
git init -q "$unborn"
cd "$unborn"
_agnoster_git_refresh
assert_true "$_AGNOSTER_GIT_REPO" unborn repository detected
assert_eq "$_AGNOSTER_GIT_REMOTE_AHEAD" '' unborn repository has no remote counts

git -C "$repo" checkout -q -- file
cd "$repo"
git add untracked-file
git commit -qm second
_AGNOSTER_GIT_UNTRACKED_CACHE[$_AGNOSTER_GIT_DIR]=false
print -r -- stash-change >> file
git stash push -qm saved
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_STASHED" true stash marker is current

git checkout -q HEAD^
_agnoster_git_refresh
assert_true "$_AGNOSTER_GIT_DETACHED" detached HEAD detected
[[ -n $_AGNOSTER_GIT_SHORT_OID ]] || fail detached short oid is present

cd /tmp
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_REPO" false state clears outside repositories
assert_eq "$_AGNOSTER_GIT_BRANCH" '' state clears when changing directories

git -C "$repo" config oh-my-zsh.hide-status 1
cd "$repo"
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_REPO" false hide-status suppresses Git state
git -C "$repo" config --unset oh-my-zsh.hide-status

remote="$root/origin.git"
git init -q --bare "$remote"
clone="$root/clone"
git clone -q "$remote" "$clone" 2>/dev/null
git -C "$clone" config core.fsmonitor false
git -C "$clone" config user.email test@example.invalid
git -C "$clone" config user.name PromptTest
print -r -- base >| "$clone/file"
git -C "$clone" add file
git -C "$clone" commit -qm base
git -C "$clone" push -q -u origin master 2>/dev/null
cd "$clone"
_TEST_FAIL_REMOTE=false
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_REMOTE_AHEAD" 0 equal upstream has zero ahead
assert_eq "$_AGNOSTER_GIT_REMOTE_BEHIND" 0 equal upstream has zero behind

print -r -- local >| "$clone/local-file"
git -C "$clone" add local-file
git -C "$clone" commit -qm local
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_REMOTE_AHEAD" 1 HEAD changes invalidate remote cache

other="$root/other"
git clone -q "$remote" "$other" 2>/dev/null
git -C "$other" config core.fsmonitor false
git -C "$other" config user.email test@example.invalid
git -C "$other" config user.name PromptTest
print -r -- remote >| "$other/remote-file"
git -C "$other" add remote-file
git -C "$other" commit -qm remote
git -C "$other" push -q origin master 2>/dev/null
git -C "$clone" fetch -q origin 2>/dev/null
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_REMOTE_BEHIND" 0 remote result remains cached within TTL
_AGNOSTER_GIT_REMOTE_CACHE_TIME=$(( EPOCHSECONDS - 6 ))
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_REMOTE_BEHIND" 1 remote result refreshes after TTL
AGNOSTER_GIT_REMOTE_CACHE_TTL=0
print -r -- remote-two >| "$other/remote-two"
git -C "$other" add remote-two
git -C "$other" commit -qm remote-two
git -C "$other" push -q origin master 2>/dev/null
git -C "$clone" fetch -q origin 2>/dev/null
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_REMOTE_BEHIND" 2 zero TTL disables remote caching
AGNOSTER_GIT_REMOTE_CACHE_TTL=5

_TEST_FAIL_REMOTE=true
print -r -- dirty >> "$clone/file"
_AGNOSTER_GIT_REMOTE_CACHE_TIME=$(( EPOCHSECONDS - 6 ))
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_UNSTAGED" true remote failure retains local status
assert_eq "$_AGNOSTER_GIT_REMOTE_AHEAD" '' remote failure clears only remote counts
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_REMOTE_BEHIND" '' failed remote counts are not resurrected from cache
_TEST_FAIL_REMOTE=false

subsrc="$root/subsrc"
git init -q "$subsrc"
git -C "$subsrc" config core.fsmonitor false
git -C "$subsrc" config user.email test@example.invalid
git -C "$subsrc" config user.name PromptTest
print -r -- submodule >| "$subsrc/file"
git -C "$subsrc" add file
git -C "$subsrc" commit -qm submodule
super="$root/super"
git init -q "$super"
git -C "$super" config core.fsmonitor false
git -C "$super" config user.email test@example.invalid
git -C "$super" config user.name PromptTest
git -C "$super" -c protocol.file.allow=always submodule add -q "$subsrc" module 2>/dev/null
git -C "$super" add .gitmodules module 2>/dev/null
git -C "$super" commit -qm super
print -r -- submodule-change >> "$super/module/file"
cd "$super"
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_DIRTY" false dirty submodule is ignored by default
GIT_STATUS_IGNORE_SUBMODULES=none
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_DIRTY" true non-ignored dirty submodule is visible
unset GIT_STATUS_IGNORE_SUBMODULES

worktree="$root/worktree"
git -C "$repo" worktree add -q "$worktree" master
cd "$worktree"
_agnoster_git_refresh
assert_true "$_AGNOSTER_GIT_REPO" linked worktree detected
[[ $_AGNOSTER_GIT_DIR == *worktrees* || $_AGNOSTER_GIT_DIR == */.git ]] || fail linked worktree has a Git directory

gitdir=$_AGNOSTER_GIT_DIR
touch "$gitdir/MERGE_HEAD"
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_MODE" ' >M<' merge mode is detected
rm "$gitdir/MERGE_HEAD"
mkdir "$gitdir/rebase-merge"
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_MODE" ' >R>' rebase mode is detected
rm -rf "$gitdir/rebase-merge"
touch "$gitdir/BISECT_LOG"
_agnoster_git_refresh
assert_eq "$_AGNOSTER_GIT_MODE" ' <B>' bisect mode is detected
rm "$gitdir/BISECT_LOG"

cd "$clone"
_agnoster_git_refresh
setopt no_errexit
false
_agnoster_precmd
setopt errexit
assert_eq "$_AGNOSTER_LAST_STATUS" 1 precmd refresh preserves command exit status

SECONDS=100
_agnoster_preexec
SECONDS=106
_agnoster_precmd
assert_eq "$_AGNOSTER_LAST_DURATION" 6 precmd records command duration in parent shell
assert_eq "$_AGNOSTER_COMMAND_RAN" false precmd consumes command lifecycle state

_AGNOSTER_LAST_DURATION=9
_AGNOSTER_COMMAND_RAN=false
_agnoster_precmd
assert_eq "$_AGNOSTER_LAST_DURATION" -1 precmd clears duration when no command ran

POWERLINE_CAPABLE=false
render=$(prompt_git)
[[ $render == *master* && $render == *'^1 v2'* ]] || fail ASCII rendering includes branch
POWERLINE_CAPABLE=true
render=$(prompt_git)
[[ $render == *$'\ue0a0'* || $render == *'↱'* || $render == *'↲'* || $render == *'\u21b1'* || $render == *'\u21b0'* ]] || fail Powerline rendering includes a branch glyph

typeset -ga _TEST_ZLE_CALLS=()
_agnoster_git_zle() {
  _TEST_ZLE_CALLS+=("$*")
  return 0
}
add-zsh-hook -d preexec _agnoster_preexec

_AGNOSTER_GIT_UNTRACKED=false
_AGNOSTER_GIT_COMMAND_GENERATION=10
_AGNOSTER_GIT_UNTRACKED_PENDING_KEY=$_AGNOSTER_GIT_DIR
_AGNOSTER_GIT_UNTRACKED_PENDING_GENERATION=10
exec {callback_fd}< <(print -rn -- true)
_AGNOSTER_GIT_UNTRACKED_FD=$callback_fd
_agnoster_git_untracked_callback $callback_fd hup
assert_eq "$_AGNOSTER_GIT_UNTRACKED" true current asynchronous result updates marker
[[ " ${_TEST_ZLE_CALLS[*]} " == *' .reset-prompt '* ]] || fail current asynchronous result requests safe ZLE redraw

_TEST_ZLE_CALLS=()
_AGNOSTER_GIT_UNTRACKED=true
_AGNOSTER_GIT_COMMAND_GENERATION=11
_AGNOSTER_GIT_UNTRACKED_PENDING_KEY=$_AGNOSTER_GIT_DIR
_AGNOSTER_GIT_UNTRACKED_PENDING_GENERATION=10
exec {callback_fd}< <(print -rn -- false)
_AGNOSTER_GIT_UNTRACKED_FD=$callback_fd
_agnoster_git_untracked_callback $callback_fd hup
assert_eq "$_AGNOSTER_GIT_UNTRACKED" true stale asynchronous result cannot overwrite newer prompt state
[[ " ${_TEST_ZLE_CALLS[*]} " != *' .reset-prompt '* ]] || fail stale asynchronous result must not redraw prompt

print -r -- 'prompt-git checks passed'
