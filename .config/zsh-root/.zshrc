# ~/.zshrc - managed via ~/.computer

# ------------------------------------------------------------------------------
# PATH
# ------------------------------------------------------------------------------
export PATH="${HOME}/.computer/bin:${PATH}"

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
