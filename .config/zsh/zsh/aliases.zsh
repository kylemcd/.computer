alias nix-rebuild='sudo -H darwin-rebuild switch --flake ~/\.computer/nix-darwin#kpm'

alias vim="nvim"
alias vi="nvim"

# git
alias gs='git status'

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
gtcs() {
    gt modify --commit -m "$*" && gt submit
}

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
