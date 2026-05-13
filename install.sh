cat > setup-dotfiles.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/dolmiaz/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
INSTALL_MODE="${INSTALL_MODE:-copy}"   # copy または link
REMOVE_LATEXMK="${REMOVE_LATEXMK:-1}"  # 1なら latexmkrc を削除

log() {
  printf '\033[1;32m[setup]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  SUDO=()
else
  SUDO=(sudo)
fi

export DEBIAN_FRONTEND=noninteractive
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

[[ -n "${HOME:-}" && -d "$HOME" ]] || die "HOME が不正です: ${HOME:-}"
have apt-get || die "このスクリプトは Ubuntu/Debian 系 apt-get 前提です"

install_apt_base() {
  log "apt パッケージをインストール中"
  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    zsh \
    direnv \
    fzf \
    gpg \
    unzip \
    software-properties-common
}

install_eza() {
  if have eza; then
    log "eza は既にあります: $(command -v eza)"
    return
  fi

  log "eza をインストール中"

  if apt-cache show eza >/dev/null 2>&1; then
    "${SUDO[@]}" apt-get install -y eza
    return
  fi

  "${SUDO[@]}" mkdir -p /etc/apt/keyrings

  tmp_key="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc -o "$tmp_key"
  "${SUDO[@]}" gpg --dearmor --batch --yes -o /etc/apt/keyrings/gierens.gpg "$tmp_key"
  rm -f "$tmp_key"

  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | "${SUDO[@]}" tee /etc/apt/sources.list.d/gierens.list >/dev/null

  "${SUDO[@]}" chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y eza
}

install_starship() {
  if have starship; then
    log "starship は既にあります: $(command -v starship)"
    return
  fi

  log "starship をインストール中"
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
}

install_zoxide() {
  if have zoxide; then
    log "zoxide は既にあります: $(command -v zoxide)"
    return
  fi

  log "zoxide をインストール中"
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
}

clone_or_update() {
  local url="$1"
  local dir="$2"

  if [[ -d "$dir/.git" ]]; then
    log "更新: $dir"
    git -C "$dir" pull --ff-only
  elif [[ -e "$dir" ]]; then
    local backup="${dir}.backup.$(date +%Y%m%d%H%M%S)"
    warn "$dir が既にあるので $backup に退避します"
    mv "$dir" "$backup"
    git clone --depth=1 "$url" "$dir"
  else
    log "clone: $url -> $dir"
    git clone --depth=1 "$url" "$dir"
  fi
}

install_zsh_plugins() {
  local plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
  mkdir -p "$plugin_dir"

  clone_or_update \
    https://github.com/zsh-users/zsh-autosuggestions \
    "$plugin_dir/zsh-autosuggestions"

  clone_or_update \
    https://github.com/zsh-users/zsh-syntax-highlighting \
    "$plugin_dir/zsh-syntax-highlighting"
}

install_dotfiles() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "dotfiles を更新中: $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only
  elif [[ -e "$DOTFILES_DIR" ]]; then
    local backup="${DOTFILES_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    warn "$DOTFILES_DIR が既にあるので $backup に退避します"
    mv "$DOTFILES_DIR" "$backup"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  else
    log "dotfiles を clone 中"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi

  chmod +x "$DOTFILES_DIR/install.sh" || true

  log "dotfiles を反映中: mode=$INSTALL_MODE"
  case "$INSTALL_MODE" in
    copy)
      "$DOTFILES_DIR/install.sh" --copy
      ;;
    link)
      "$DOTFILES_DIR/install.sh"
      ;;
    *)
      die "INSTALL_MODE は copy または link にしてください: $INSTALL_MODE"
      ;;
  esac
}

remove_latexmk() {
  if [[ "$REMOVE_LATEXMK" = "1" ]]; then
    log "latexmkrc を削除"
    rm -f "$HOME/.config/latexmk/latexmkrc"
    rmdir "$HOME/.config/latexmk" 2>/dev/null || true
  fi
}

patch_zshrc() {
  local zshrc="$HOME/.config/zsh/.zshrc"
  [[ -f "$zshrc" ]] || die "$zshrc がありません"

  log ".zshrc を補正中"

  # 以前手動で足した ls --color=auto があると eza alias を上書きするので消す
  sed -i '/# colorize ls/,+4d' "$zshrc" || true
  sed -i "/alias ls='ls --color=auto'/d" "$zshrc" || true
  sed -i "/alias ll='ls -la --color=auto'/d" "$zshrc" || true
  sed -i "/alias la='ls -A --color=auto'/d" "$zshrc" || true

  # 再実行しても二重追加しない
  sed -i '/# >>> local WSL\/Ubuntu plugin loader >>>/,/# <<< local WSL\/Ubuntu plugin loader <<</d' "$zshrc" || true

  cat >> "$zshrc" <<'ZSHRC_EOF'

# >>> local WSL/Ubuntu plugin loader >>>
# apt版 fzf が `fzf --zsh` に未対応の場合の fallback
if command -v fzf >/dev/null 2>&1 && ! fzf --zsh >/dev/null 2>&1; then
  [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -r /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
fi

_zsh_plugin_root="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

if [[ -r "$_zsh_plugin_root/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$_zsh_plugin_root/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-syntax-highlighting はできるだけ最後に読む
if [[ -r "$_zsh_plugin_root/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$_zsh_plugin_root/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset _zsh_plugin_root
# <<< local WSL/Ubuntu plugin loader <<<
ZSHRC_EOF
}

install_vim_plug_and_plugins() {
  log "vim-plug をインストール中"

  mkdir -p "$HOME/.local/share/vim/autoload" "$HOME/.vim/autoload"

  curl -fsSLo "$HOME/.local/share/vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  cp "$HOME/.local/share/vim/autoload/plug.vim" "$HOME/.vim/autoload/plug.vim"

  log "Vim plugin をインストール中"
  if have vim; then
    vim +'PlugInstall --sync' +qall || warn "Vim plugin install に失敗しました。後で vim 内で :PlugInstall を実行してください"
  else
    warn "vim が見つかりません"
  fi
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  local user_name
  user_name="${USER:-$(id -un)}"

  local current_shell
  current_shell="$(getent passwd "$user_name" | awk -F: '{print $7}')"

  if [[ "$current_shell" != "$zsh_path" ]]; then
    log "default shell を zsh に変更中: $zsh_path"
    "${SUDO[@]}" chsh -s "$zsh_path" "$user_name" || \
      warn "chsh に失敗しました。手動で実行してください: chsh -s $zsh_path"
  else
    log "default shell は既に zsh です"
  fi
}

verify() {
  log "確認"

  zsh -lic '
    echo "SHELL=$SHELL"
    echo "ZDOTDIR=$ZDOTDIR"
    command -v starship || true
    command -v fzf || true
    command -v zoxide || true
    command -v direnv || true
    command -v eza || true
    type ls || true
  ' || true
}

main() {
  install_apt_base
  install_eza
  install_starship
  install_zoxide
  install_zsh_plugins
  install_dotfiles
  remove_latexmk
  patch_zshrc
  install_vim_plug_and_plugins
  set_default_shell
  verify

  log "完了"
  log "今のシェルに反映するなら: exec zsh"
  log "WSLを開き直すと default shell の変更も反映されます"
}

main "$@"
EOF

chmod +x setup-dotfiles.sh
./setup-dotfiles.sh
