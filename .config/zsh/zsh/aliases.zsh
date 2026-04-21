alias nix-rebuild='sudo -H darwin-rebuild switch --flake ~/\.computer/nix-darwin#kpm'

alias vim="nvim"
alias vi="nvim"

# git
alias gs='git status'
alias diff='critique'
alias diff:main='critique main'

# agent changes review
alias ar="tuicr"
alias ar:main="tuicr -r main..HEAD"

# gh pr review
alias pr="gh dash"

# zoxide
alias cd='z'

# Get Local IP
alias localip="ipconfig getifaddr en0"
alias publicip="curl ifconfig.me"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

# graphite
alias gta="gt add ."
gtc() {
    gt modify --commit -m "$*"
}
alias gts="gt submit"
# commit and submit
gtcs() {
    gt modify --commit -m "$*" && gt ss
}
# add all and commit and submit
gtacs() {
    gt add . && gt modify --commit -m "$*" && gt ss
}
alias gtms="gt checkout main && gt sync"

# git
alias ga="git add ."
unalias gc 2>/dev/null
gc() {
    git commit -m "$*"
}
alias gp="git push"
# add and commit and push
gacp() {
    git add . && git commit -m "$*" && git push
}
alias gcm="git checkout main"
alias gms="git checkout main && git pull"

# opencode
alias oc="opencode"


# cursor cli
alias agent="cursor-agent"

# tmux
alias ts="tmux"
tk() {
  read -q "REPLY?Kill tmux server? [y/N] " && echo && tmux kill-server
}
alias tl="tmux ls"
_tsp_split() { ~/.computer/.config/tmux/tmux/split-pane.sh "$1"; }
alias tsp="_tsp_split 2"
alias tsp2="_tsp_split 2"
tsp3() { _tsp_split 3; }
tsp4() { _tsp_split 4; }
tsp5() { _tsp_split 5; }
alias tc="~/.computer/.config/tmux/tmux/close-pane.sh"

# Save clipboard image to /tmp and print the path for use in OpenCode via @
imgpaste() {
  local dest="/tmp/paste-$(date +%s).png"
  osascript -e "
    set theImage to the clipboard as «class PNGf»
    set fileRef to open for access POSIX file \"$dest\" with write permission
    write theImage to fileRef
    close access fileRef
  " 2>/dev/null && echo "$dest" || echo "No image in clipboard"
}

# kill the port number
kp() { lsof -ti :$1 | xargs kill -9; }

# worktrees (legacy git helpers — Worktrunk's wt command is preferred)
# These are kept as fallbacks. Worktrunk handles: switch, list, remove, merge.
WT_DIR="${WT_DIR:-..}"
wtadd()    { git worktree add -b "$1" "$WT_DIR/$1" "${2:-main}"; }
wtrm()     { git worktree remove "$WT_DIR/$1" && [ "${2:-}" != "-k" ] && git branch -d "$1" 2>/dev/null; }
wtpr()     { git fetch origin "$1" && git worktree add --detach "$WT_DIR/${2:-${1//\//-}}" "origin/$1"; }
wtcd()     { cd "$WT_DIR/$1"; }
# interactive worktree picker — fuzzy select then cd
wtpick() {
  local selected
  selected=$(git worktree list | tail -n +2 | fzf \
    --prompt="worktree> " \
    --preview="git -C {1} log --oneline -10 2>/dev/null" \
    --preview-window=right:50% \
    | awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}
wtprune() { git worktree prune -v; }

# Clean up worktrees that are merged/integrated into main.
# Skips current worktree, worktrees with uncommitted changes, and main.
# Pass -f to also force-remove worktrees with untracked files.
wtclean() {
  local force_flag=""
  [[ "${1:-}" == "-f" ]] && force_flag="--force"

  local branches
  branches=$(wt list --format=json 2>/dev/null \
    | jq -r '.[] | select(
        (.main_state == "integrated" or .main_state == "empty") and
        .is_current == false and
        .is_main == false and
        (.working_tree.staged == false) and
        (.working_tree.modified == false)
      ) | .branch')

  if [[ -z "$branches" ]]; then
    echo "No merged worktrees to clean up."
    return 0
  fi

  echo "Worktrees to remove:"
  echo "$branches" | sed 's/^/  /'
  echo
  read -q "REPLY?Remove these? [y/N] " && echo || { echo "Cancelled."; return 1; }

  echo "$branches" | while read -r branch; do
    echo "Removing $branch..."
    wt remove $force_flag "$branch"
  done
}
