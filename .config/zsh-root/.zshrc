# ~/.zshrc - managed via ~/.computer

# ------------------------------------------------------------------------------
# PATH
# ------------------------------------------------------------------------------
export PATH="${HOME}/.computer/bin:${HOME}/.bun/bin:${PATH}"

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ------------------------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------------------------
export ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME=""  # Using oh-my-posh for prompt instead
plugins=(git npm history node)
source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="${HOME}/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ------------------------------------------------------------------------------
# Plugins (via Homebrew)
# ------------------------------------------------------------------------------
# zsh-autosuggestions
if [[ -f $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# zsh-syntax-highlighting (must be last plugin)
if [[ -f $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ------------------------------------------------------------------------------
# Slipstream shell colors
# ------------------------------------------------------------------------------
typeset -g SLIPSTREAM_BG="#000000"
typeset -g SLIPSTREAM_FG="#e2e2e6"
typeset -g SLIPSTREAM_MUTED="#5c5c64"
typeset -g SLIPSTREAM_TEAL="#5cb8a2"
typeset -g SLIPSTREAM_TEAL_BRIGHT="#7cd4be"
typeset -g SLIPSTREAM_SKY="#8cb8dc"
typeset -g SLIPSTREAM_ROSE="#e85c6c"

# File listing colors (BSD ls + GNU/eza)
export CLICOLOR=1
export LSCOLORS="DxcxexcxDxexexaxaxexex"
export LS_COLORS="di=38;2;244;213;141:ln=38;2;140;184;220:ex=38;2;244;213;141:fi=0:*.md=38;2;226;226;230"

# Autosuggestion color
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${SLIPSTREAM_MUTED}"

# Syntax highlight colors
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]="fg=${SLIPSTREAM_MUTED}"
ZSH_HIGHLIGHT_STYLES[command]="fg=${SLIPSTREAM_TEAL}"
ZSH_HIGHLIGHT_STYLES[alias]="fg=${SLIPSTREAM_SKY}"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=${SLIPSTREAM_SKY}"
ZSH_HIGHLIGHT_STYLES[function]="fg=${SLIPSTREAM_TEAL_BRIGHT}"
ZSH_HIGHLIGHT_STYLES[path]="fg=${SLIPSTREAM_TEAL_BRIGHT}"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=${SLIPSTREAM_SKY}"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=${SLIPSTREAM_FG}"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=${SLIPSTREAM_FG}"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=${SLIPSTREAM_ROSE}"

# Completion list colors
zstyle ':completion:*' list-colors "ma=0;38;2;226;226;230:di=0;38;2;124;212;190:ln=0;38;2;140;184;220:ex=0;38;2;92;184;162"

# ------------------------------------------------------------------------------
# asdf version manager
# ------------------------------------------------------------------------------
if [[ -f $(brew --prefix asdf)/libexec/asdf.sh ]]; then
  source $(brew --prefix asdf)/libexec/asdf.sh
fi

# asdf-erlang build settings (link against Homebrew OpenSSL)
export ASDF_ERLANG_OPENSSL_DIR="$(brew --prefix openssl@3 2>/dev/null || echo '/opt/homebrew/opt/openssl@3')"
export KERL_CONFIGURE_OPTIONS="--without-javac --without-erl_interface --with-ssl=${ASDF_ERLANG_OPENSSL_DIR}"
export KERL_BUILD_DOCS=no
export CPPFLAGS="-I${ASDF_ERLANG_OPENSSL_DIR}/include ${CPPFLAGS:-}"
export LDFLAGS="-L${ASDF_ERLANG_OPENSSL_DIR}/lib ${LDFLAGS:-}"
export PKG_CONFIG_PATH="${ASDF_ERLANG_OPENSSL_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# ------------------------------------------------------------------------------
# Custom configs
# ------------------------------------------------------------------------------
[[ -f ~/.config/zsh/evals.zsh ]] && source ~/.config/zsh/evals.zsh
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/kyle/.lmstudio/bin"
# End of LM Studio CLI section

# Editor for OpenCode
export EDITOR=nvim

# pnpm
export PNPM_HOME="/Users/kyle/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
