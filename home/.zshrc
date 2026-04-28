# ~/.zshrc
#
# Interactive shell configuration.

# ----------------------------------------------------------
# XDG Base Directory Fallbacks
# ----------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ----------------------------------------------------------
# Helper Functions
# ----------------------------------------------------------
path_prepend_if_exists() {
  local dir="$1"

  if [[ -d "$dir" ]]; then
    path=("$dir" "${path[@]}")
  fi
}

path_append_if_exists() {
  local dir="$1"

  if [[ -d "$dir" ]]; then
    path+=("$dir")
  fi
}

fpath_prepend_if_exists() {
  local dir="$1"

  if [[ -d "$dir" ]]; then
    fpath=("$dir" "${fpath[@]}")
  fi
}

source_if_exists() {
  local file="$1"

  if [[ -r "$file" ]]; then
    source "$file"
  fi
}

# ----------------------------------------------------------
# Directory Preparation
# ----------------------------------------------------------
mkdir -p \
  "$XDG_CACHE_HOME/zsh" \
  "$XDG_STATE_HOME/zsh" \
  "$XDG_STATE_HOME/less" \
  "$XDG_STATE_HOME/node" \
  "$XDG_STATE_HOME/sqlite" \
  "$XDG_STATE_HOME/psql"

# ----------------------------------------------------------
# Homebrew Fallback
# ----------------------------------------------------------
if [[ "$OSTYPE" == darwin* ]] && ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ----------------------------------------------------------
# Homebrew Prefixes
# ----------------------------------------------------------
brew_prefixes=()

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  brew_prefixes+=("$HOMEBREW_PREFIX")
fi

brew_prefixes+=("/opt/homebrew" "/usr/local")
typeset -U brew_prefixes

# ----------------------------------------------------------
# PATH
# ----------------------------------------------------------
path_prepend_if_exists "$HOME/.local/bin"
path_prepend_if_exists "$HOME/bin"

for brew_prefix in "${brew_prefixes[@]}"; do
  path_prepend_if_exists "$brew_prefix/opt/llvm/bin"
  path_append_if_exists "$brew_prefix/opt/fzf/bin"
done

# ----------------------------------------------------------
# Go
# ----------------------------------------------------------
export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
mkdir -p "$GOPATH"
path_prepend_if_exists "$GOPATH/bin"

# ----------------------------------------------------------
# Zsh Options
# ----------------------------------------------------------
setopt interactive_comments
setopt no_beep

# ----------------------------------------------------------
# History
# ----------------------------------------------------------
export HISTFILE="${HISTFILE:-$XDG_STATE_HOME/zsh/history}"
export HISTSIZE="${HISTSIZE:-50000}"
export SAVEHIST="${SAVEHIST:-50000}"

setopt append_history
setopt inc_append_history
setopt extended_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_verify

# ----------------------------------------------------------
# Completion
# ----------------------------------------------------------
for brew_prefix in "${brew_prefixes[@]}"; do
  fpath_prepend_if_exists "$brew_prefix/share/zsh/site-functions"
done

autoload -Uz compinit

zcompdump="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

if [[ -f "$zcompdump" ]]; then
  compinit -C -d "$zcompdump"
else
  compinit -d "$zcompdump"
fi

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${LS_COLORS:-}"

# ----------------------------------------------------------
# fzf
# ----------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  fi
fi

# ----------------------------------------------------------
# zoxide
# ----------------------------------------------------------
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ----------------------------------------------------------
# direnv
# ----------------------------------------------------------
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# ----------------------------------------------------------
# Aliases
# ----------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --git --group-directories-first'
  alias ll='eza -lah --icons --git --group-directories-first'
  alias la='eza -a --icons --git --group-directories-first'
  alias tree='eza --tree --icons --git --group-directories-first'
else
  alias ll='ls -lah'
  alias la='ls -A'
fi

alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ----------------------------------------------------------
# rbenv
# ----------------------------------------------------------
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

# ----------------------------------------------------------
# Conda
# ----------------------------------------------------------
if [[ -z "${CONDA_SHLVL:-}" ]]; then
  conda_candidates=()

  if command -v conda >/dev/null 2>&1; then
    conda_candidates+=("$(command -v conda)")
  fi

  conda_candidates+=(
    "/opt/anaconda3/bin/conda"
    "/opt/miniconda3/bin/conda"
    "$HOME/anaconda3/bin/conda"
    "$HOME/miniconda3/bin/conda"
    "$XDG_DATA_HOME/miniconda3/bin/conda"
  )

  for conda_bin in "${conda_candidates[@]}"; do
    if [[ -x "$conda_bin" ]]; then
      __conda_setup="$("$conda_bin" shell.zsh hook 2>/dev/null)"

      if [[ $? -eq 0 ]]; then
        eval "$__conda_setup"
      else
        conda_base="${conda_bin:h:h}"

        if [[ -r "$conda_base/etc/profile.d/conda.sh" ]]; then
          source "$conda_base/etc/profile.d/conda.sh"
        else
          path_prepend_if_exists "$conda_base/bin"
        fi

        unset conda_base
      fi

      unset __conda_setup
      break
    fi
  done

  unset conda_candidates conda_bin
fi

# ----------------------------------------------------------
# nvm
# ----------------------------------------------------------
if [[ -n "${NVM_DIR:-}" ]]; then
  source_if_exists "$NVM_DIR/nvm.sh"
  source_if_exists "$NVM_DIR/bash_completion"
fi

# ----------------------------------------------------------
# 1Password SSH Agent
# ----------------------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
  op_ssh_auth_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

  if [[ -S "$op_ssh_auth_sock" ]]; then
    export SSH_AUTH_SOCK="$op_ssh_auth_sock"
  fi

  unset op_ssh_auth_sock
fi

# ----------------------------------------------------------
# Starship
# ----------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ----------------------------------------------------------
# Zsh Autosuggestions
# ----------------------------------------------------------
for brew_prefix in "${brew_prefixes[@]}"; do
  source_if_exists "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
done

# ----------------------------------------------------------
# Zsh Syntax Highlighting
# ----------------------------------------------------------
for brew_prefix in "${brew_prefixes[@]}"; do
  source_if_exists "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
done

# ----------------------------------------------------------
# PATH Cleanup
# ----------------------------------------------------------
typeset -U path
export PATH

# ----------------------------------------------------------
# Cleanup
# ----------------------------------------------------------
unset brew_prefix brew_prefixes zcompdump
unset -f path_prepend_if_exists path_append_if_exists fpath_prepend_if_exists source_if_exists
