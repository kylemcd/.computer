alias nix-rebuild='sudo -H darwin-rebuild switch --flake ~/\.computer/nix-darwin#kpm'

alias vim="nvim"
alias vi="nvim"

# git
alias gs='git status'

# zoxide
eval "$(zoxide init zsh)"
alias cd='z'

# Get Local IP
alias localip="ipconfig getifaddr en0"
alias publicip="curl ifconfig.me"

# graphite
alias gta="gt add ."
gtc() {
    gt modify --commit -m "$*"
}
alias gts="gt submit"
gtcs() {
    gt modify --commit -m "$*" && gt submit
}

eval "$(oh-my-posh init zsh --config ~/.computer/zsh/oh-my-posh.json)"