alias nix-rebuild='sudo -H darwin-rebuild switch --flake ~/\.computer/nix-darwin#kpm'

alias vim="nvim"
alias vi="nvim"

# git
alias gs='git status'
alias diff='critique'
alias diff:main='critique main'

# agent changes review
alias ar="tuicr"

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
    gt modify --commit -m "$*" && gt submit
}
# add all and commit and submit
gtacs() {
    gt add . && gt modify --commit -m "$*" && gt submit
}

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

# opencode
alias oc="opencode"

# tmux
alias ts="tmux"
alias tk="tmux kill-server"
alias tl="tmux ls"

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
