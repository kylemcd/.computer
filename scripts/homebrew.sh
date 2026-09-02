#!/usr/bin/env bash

# Scripts do not load .zshrc. Select Homebrew explicitly so a stale PATH
# cannot send an Apple Silicon install through the old Intel prefix.
computer_homebrew_env() {
  local brew_bin=""
  case "$(uname -s):$(uname -m)" in
    Darwin:arm64) brew_bin=/opt/homebrew/bin/brew ;;
    Darwin:x86_64) brew_bin=/usr/local/bin/brew ;;
    Linux:*) brew_bin=/home/linuxbrew/.linuxbrew/bin/brew ;;
  esac

  if [[ -n "${brew_bin}" && -x "${brew_bin}" ]]; then
    local brew_env
    brew_env="$("${brew_bin}" shellenv bash)" || return
    eval "${brew_env}"
  fi
}
