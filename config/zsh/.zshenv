# ----------------------------------------------------------
# XDG Base Directory
# ----------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"

# macOS does not provide /run/user/$UID.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-${${TMPDIR:-/tmp}%/}/xdg-runtime-$UID}"

# ----------------------------------------------------------
# macOS
# ----------------------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
  export SHELL_SESSIONS_DISABLE="${SHELL_SESSIONS_DISABLE:-1}"
fi

# ----------------------------------------------------------
# XDG-aware Tools
# ----------------------------------------------------------
export DOCKER_CONFIG="${DOCKER_CONFIG:-$XDG_CONFIG_HOME/docker}"
export JUPYTER_CONFIG_DIR="${JUPYTER_CONFIG_DIR:-$XDG_CONFIG_HOME/jupyter}"
export IPYTHONDIR="${IPYTHONDIR:-$XDG_CONFIG_HOME/ipython}"
export MPLCONFIGDIR="${MPLCONFIGDIR:-$XDG_CONFIG_HOME/matplotlib}"

# ----------------------------------------------------------
# Shell History
# ----------------------------------------------------------
if [[ -z "${HISTFILE:-}" || "$HISTFILE" = "$HOME/.zsh_history" || "$HISTFILE" = "$ZDOTDIR/.zsh_history" ]]; then
  export HISTFILE="$XDG_STATE_HOME/zsh/history"
else
  export HISTFILE
fi

export LESSHISTFILE="${LESSHISTFILE:-$XDG_STATE_HOME/less/history}"

# ----------------------------------------------------------
# CLI History
# ----------------------------------------------------------
export NODE_REPL_HISTORY="${NODE_REPL_HISTORY:-$XDG_STATE_HOME/node/repl_history}"
export SQLITE_HISTORY="${SQLITE_HISTORY:-$XDG_STATE_HOME/sqlite/history}"
export PSQL_HISTORY="${PSQL_HISTORY:-$XDG_STATE_HOME/psql/history}"

# ----------------------------------------------------------
# npm
# ----------------------------------------------------------
export NPM_CONFIG_USERCONFIG="${NPM_CONFIG_USERCONFIG:-$XDG_CONFIG_HOME/npm/npmrc}"
export NPM_CONFIG_CACHE="${NPM_CONFIG_CACHE:-$XDG_CACHE_HOME/npm}"

# ----------------------------------------------------------
# Language Managers
# ----------------------------------------------------------
export RBENV_ROOT="${RBENV_ROOT:-$XDG_DATA_HOME/rbenv}"
export NVM_DIR="${NVM_DIR:-$XDG_DATA_HOME/nvm}"

if [[ -d "$XDG_DATA_HOME/cargo" || ! -d "$HOME/.cargo" ]]; then
  export CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
fi

if [[ -d "$XDG_DATA_HOME/rustup" || ! -d "$HOME/.rustup" ]]; then
  export RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"
fi

# ----------------------------------------------------------
# Python
# ----------------------------------------------------------
if [[ -z "${PYTHONSTARTUP:-}" ]]; then
  if [[ -r "$XDG_CONFIG_HOME/python/pythonrc" ]]; then
    export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
  elif [[ -r "$HOME/python/pythonrc" ]]; then
    export PYTHONSTARTUP="$HOME/python/pythonrc"
  else
    export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
  fi
fi

# ----------------------------------------------------------
# Pager
# ----------------------------------------------------------
export PAGER="${PAGER:-less}"
export MANPAGER="${MANPAGER:-less -R}"
export LESS="${LESS:--F -R -X -i}"

# ----------------------------------------------------------
# Terminal
# ----------------------------------------------------------
export COLORTERM="${COLORTERM:-truecolor}"
