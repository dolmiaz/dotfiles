# ----------------------------------------------------------
# XDG Directory Preparation
# ----------------------------------------------------------
mkdir -p \
  "$XDG_CONFIG_HOME" \
  "$XDG_CACHE_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$XDG_RUNTIME_DIR" \
  "$XDG_CONFIG_HOME/docker" \
  "$XDG_CONFIG_HOME/jupyter" \
  "$XDG_CONFIG_HOME/ipython" \
  "$XDG_CONFIG_HOME/matplotlib" \
  "$XDG_CONFIG_HOME/npm" \
  "$XDG_CONFIG_HOME/python" \
  "$XDG_CACHE_HOME/npm" \
  "$XDG_STATE_HOME/zsh" \
  "$XDG_STATE_HOME/less" \
  "$XDG_STATE_HOME/node" \
  "$XDG_STATE_HOME/sqlite" \
  "$XDG_STATE_HOME/psql"

chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

# ----------------------------------------------------------
# PATH Helpers
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

# ----------------------------------------------------------
# Homebrew
# ----------------------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ----------------------------------------------------------
# User Local Binaries
# ----------------------------------------------------------
path_prepend_if_exists "$HOME/.local/bin"
path_prepend_if_exists "$HOME/bin"

# ----------------------------------------------------------
# JetBrains Toolbox
# ----------------------------------------------------------
path_append_if_exists "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# ----------------------------------------------------------
# Python.org Framework Pythons on macOS
# ----------------------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
  for python_version in 3.12 3.13 3.11; do
    python_bin="/Library/Frameworks/Python.framework/Versions/$python_version/bin"

    if [[ -d "$python_bin" ]]; then
      path=("$python_bin" "${path[@]}")
    fi
  done

  unset python_version python_bin
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
# Editor
# ----------------------------------------------------------
if [[ -z "${VISUAL:-}" && -z "${EDITOR:-}" ]]; then
  if command -v nvim >/dev/null 2>&1; then
    export VISUAL="nvim"
    export EDITOR="nvim"
  elif command -v vim >/dev/null 2>&1; then
    export VISUAL="vim"
    export EDITOR="vim"
  else
    export VISUAL="vi"
    export EDITOR="vi"
  fi
elif [[ -n "${VISUAL:-}" && -z "${EDITOR:-}" ]]; then
  export EDITOR="$VISUAL"
elif [[ -z "${VISUAL:-}" && -n "${EDITOR:-}" ]]; then
  export VISUAL="$EDITOR"
fi

# ----------------------------------------------------------
# GPG
# ----------------------------------------------------------
if [[ -t 0 ]]; then
  export GPG_TTY="$(tty)"
fi

# ----------------------------------------------------------
# PATH Cleanup
# ----------------------------------------------------------
typeset -U path
export PATH

# ----------------------------------------------------------
# Cleanup
# ----------------------------------------------------------
unset -f path_prepend_if_exists path_append_if_exists
