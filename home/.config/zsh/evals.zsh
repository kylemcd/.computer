eval "$(zoxide init zsh)"
eval "$(oh-my-posh init zsh --config ~/.config/zsh/oh-my-posh.json)"
eval "$(/opt/homebrew/bin/brew shellenv)"
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi