#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

MODE="link"
DRY_RUN=0
INSTALL_DEPS=1
INSTALL_VIM_PLUG=1
SET_DEFAULT_ZSH=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_HOME="${DOTFILES_TARGET_HOME:-$HOME}"
BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$TARGET_HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)}"

log() {
  printf '\033[1;32m[install]\033[0m %s\n' "$*"
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

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

usage() {
  cat <<USAGE
Usage:
  ./install.sh [options]

Options:
  --link          symlink で配置する。デフォルト
  --copy          実体コピーで配置する
  --dry-run       変更内容だけ表示する
  --no-deps       apt / brew / starship / zoxide / zsh plugin を入れない
  --no-vim-plug   vim-plug / Vim plugin を入れない
  --no-chsh       default shell を zsh に変えない
  -h, --help      ヘルプ表示

Environment:
  DOTFILES_TARGET_HOME=/path/to/home
  DOTFILES_BACKUP_DIR=/path/to/backup
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --link)
      MODE="link"
      ;;
    --copy)
      MODE="copy"
      ;;
    --dry-run)
      DRY_RUN=1
      INSTALL_DEPS=0
      INSTALL_VIM_PLUG=0
      SET_DEFAULT_ZSH=0
      ;;
    --no-deps)
      INSTALL_DEPS=0
      ;;
    --no-vim-plug)
      INSTALL_VIM_PLUG=0
      ;;
    --no-chsh)
      SET_DEFAULT_ZSH=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

if [[ "${EUID:-$(id -u)}" -eq 0 && -n "${SUDO_USER:-}" ]]; then
  die "sudo ./install.sh ではなく、通常ユーザーで ./install.sh を実行してください。必要な箇所だけ sudo します。"
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  SUDO=()
else
  SUDO=(sudo)
fi

[[ -d "$SCRIPT_DIR/home" ]] || die "$SCRIPT_DIR/home が見つかりません"
[[ -d "$SCRIPT_DIR/config" ]] || die "$SCRIPT_DIR/config が見つかりません"
[[ -d "$TARGET_HOME" ]] || die "TARGET_HOME が見つかりません: $TARGET_HOME"

export DEBIAN_FRONTEND=noninteractive
export PATH="$TARGET_HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

OS_NAME="$(uname -s)"

backup_existing() {
  local dst="$1"
  local rel
  local bak

  rel="${dst#$TARGET_HOME/}"
  bak="$BACKUP_DIR/$rel"

  run mkdir -p "$(dirname "$bak")"

  log "backup: $dst -> $bak"
  run mv "$dst" "$bak"
}

same_symlink() {
  local src="$1"
  local dst="$2"

  [[ -L "$dst" ]] || return 1

  local resolved
  resolved="$(resolve_path "$dst" 2>/dev/null || true)"

  [[ "$resolved" == "$src" ]]
}

resolve_path() {
  local path="$1"
  local dir
  local base

  if [[ -d "$path" ]]; then
    (cd -P "$path" && pwd -P)
    return
  fi

  dir="$(dirname "$path")"
  base="$(basename "$path")"

  if [[ -L "$path" ]]; then
    local target
    target="$(readlink "$path")"

    if [[ "$target" = /* ]]; then
      resolve_path "$target"
    else
      resolve_path "$dir/$target"
    fi
    return
  fi

  printf '%s/%s\n' "$(cd -P "$dir" && pwd -P)" "$base"
}

place_file() {
  local src="$1"
  local dst="$2"

  src="$(resolve_path "$src")"

  run mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$MODE" == "link" ]] && same_symlink "$src" "$dst"; then
      log "skip: $dst already linked"
      return
    fi

    backup_existing "$dst"
  fi

  case "$MODE" in
    copy)
      log "copy: $src -> $dst"
      run cp -a "$src" "$dst"
      ;;
    link)
      log "link: $src -> $dst"
      run ln -s "$src" "$dst"
      ;;
    *)
      die "invalid mode: $MODE"
      ;;
  esac
}

deploy_tree() {
  local src_root="$1"
  local dst_root="$2"

  find "$src_root" -type f ! -name '.DS_Store' -print0 |
    while IFS= read -r -d '' src; do
      local rel
      rel="${src#$src_root/}"
      place_file "$src" "$dst_root/$rel"
    done
}

install_apt_deps() {
  have apt-get || {
    warn "apt-get が見つからないので apt パッケージ導入をスキップします"
    return
  }

  log "apt パッケージをインストール中"

  run "${SUDO[@]}" apt-get update
  run "${SUDO[@]}" apt-get install -y \
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

  if ! have eza; then
    if apt-cache show eza >/dev/null 2>&1; then
      run "${SUDO[@]}" apt-get install -y eza
    else
      log "apt 標準に eza が無いので eza の apt repository を追加します"

      tmp_key="$(mktemp)"
      curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc -o "$tmp_key"

      run "${SUDO[@]}" mkdir -p /etc/apt/keyrings
      run "${SUDO[@]}" gpg --dearmor --batch --yes -o /etc/apt/keyrings/gierens.gpg "$tmp_key"
      rm -f "$tmp_key"

      if [[ "$DRY_RUN" -eq 1 ]]; then
        log "dry-run: /etc/apt/sources.list.d/gierens.list を作成予定"
      else
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" |
          "${SUDO[@]}" tee /etc/apt/sources.list.d/gierens.list >/dev/null
      fi

      run "${SUDO[@]}" chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
      run "${SUDO[@]}" apt-get update
      run "${SUDO[@]}" apt-get install -y eza
    fi
  fi
}

setup_homebrew_path() {
  have brew && return

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_brew_deps() {
  setup_homebrew_path

  have brew || {
    warn "Homebrew が見つからないので brew パッケージ導入をスキップします"
    return
  }

  log "brew パッケージをインストール中"

  run brew install \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    zsh \
    direnv \
    fzf \
    gnupg \
    unzip \
    eza \
    starship \
    zoxide \
    zsh-autosuggestions \
    zsh-syntax-highlighting
}

install_deps() {
  if have apt-get; then
    install_apt_deps
    return
  fi

  if [[ "$OS_NAME" == "Darwin" ]]; then
    install_brew_deps
    return
  fi

  warn "対応している package manager が見つからないのでパッケージ導入をスキップします"
}

install_starship() {
  if have starship; then
    log "starship は既にあります: $(command -v starship)"
    return
  fi

  log "starship をインストール中"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: starship installer を実行予定"
  else
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
  fi
}

install_zoxide() {
  if have zoxide; then
    log "zoxide は既にあります: $(command -v zoxide)"
    return
  fi

  log "zoxide をインストール中"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: zoxide installer を実行予定"
  else
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi
}

clone_or_update_root() {
  local url="$1"
  local dir="$2"

  run "${SUDO[@]}" mkdir -p "$(dirname "$dir")"

  if [[ -d "$dir/.git" ]]; then
    log "update: $dir"
    run "${SUDO[@]}" git -C "$dir" pull --ff-only
  elif [[ -e "$dir" ]]; then
    local bak="${dir}.backup.$(date +%Y%m%d%H%M%S)"
    warn "$dir が既にあるので退避します: $bak"
    run "${SUDO[@]}" mv "$dir" "$bak"
    log "clone: $url -> $dir"
    run "${SUDO[@]}" git clone --depth=1 "$url" "$dir"
  else
    log "clone: $url -> $dir"
    run "${SUDO[@]}" git clone --depth=1 "$url" "$dir"
  fi
}

install_zsh_plugins() {
  setup_homebrew_path

  if have brew; then
    local brew_prefix
    brew_prefix="$(brew --prefix)"

    if [[ -r "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" &&
          -r "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
      log "zsh plugin は Homebrew のものを使います: $brew_prefix/share"
      return
    fi
  fi

  # config/zsh/.zshrc は /usr/local/share も読むので、fallback としてそこへ入れる。
  clone_or_update_root \
    https://github.com/zsh-users/zsh-autosuggestions \
    /usr/local/share/zsh-autosuggestions

  clone_or_update_root \
    https://github.com/zsh-users/zsh-syntax-highlighting \
    /usr/local/share/zsh-syntax-highlighting
}

install_vim_plug_and_plugins() {
  log "vim-plug をインストール中"

  mkdir -p "$TARGET_HOME/.local/share/vim/autoload" "$TARGET_HOME/.vim/autoload"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: plug.vim をインストール予定"
    return
  fi

  curl -fsSLo "$TARGET_HOME/.local/share/vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  cp "$TARGET_HOME/.local/share/vim/autoload/plug.vim" "$TARGET_HOME/.vim/autoload/plug.vim"

  if [[ "$TARGET_HOME" != "$HOME" ]]; then
    warn "TARGET_HOME が現在の HOME と違うので Vim plugin install はスキップします"
    return
  fi

  if have vim; then
    log "Vim plugin をインストール中"
    vim +'PlugInstall --sync' +qall || warn "Vim plugin install に失敗しました。後で vim 内で :PlugInstall を実行してください"
  else
    warn "vim が見つかりません"
  fi
}

current_login_shell() {
  local user_name="$1"

  if have getent; then
    getent passwd "$user_name" 2>/dev/null | awk -F: '{print $7}' || true
    return
  fi

  if [[ "$OS_NAME" == "Darwin" ]] && have dscl; then
    dscl . -read "/Users/$user_name" UserShell 2>/dev/null | awk '{print $2}' || true
    return
  fi

  awk -F: -v user="$user_name" '$1 == user {print $7}' /etc/passwd 2>/dev/null || true
}

set_default_shell_to_zsh() {
  [[ "$TARGET_HOME" == "$HOME" ]] || {
    warn "TARGET_HOME が現在の HOME と違うので chsh はスキップします"
    return
  }

  have zsh || {
    warn "zsh が見つからないので default shell 変更をスキップします"
    return
  }

  local zsh_path
  zsh_path="$(command -v zsh)"

  local user_name
  user_name="${USER:-$(id -un)}"

  if ! grep -qxF "$zsh_path" /etc/shells; then
    log "/etc/shells に zsh を追加: $zsh_path"

    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "dry-run: echo $zsh_path >> /etc/shells"
    else
      echo "$zsh_path" | "${SUDO[@]}" tee -a /etc/shells >/dev/null
    fi
  fi

  local current_shell
  current_shell="$(current_login_shell "$user_name")"
  current_shell="${current_shell:-${SHELL:-}}"

  if [[ "$current_shell" == "$zsh_path" ]]; then
    log "default shell は既に zsh です: $zsh_path"
    return
  fi

  log "default shell を zsh に変更中: $user_name -> $zsh_path"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: chsh -s $zsh_path $user_name"
  elif "${SUDO[@]}" chsh -s "$zsh_path" "$user_name"; then
    return
  elif [[ "$OS_NAME" == "Darwin" ]]; then
    die "chsh に失敗しました"
  elif have usermod; then
    "${SUDO[@]}" usermod -s "$zsh_path" "$user_name"
  else
    die "chsh に失敗し、usermod も見つかりません"
  fi
}

verify() {
  [[ "$TARGET_HOME" == "$HOME" ]] || return 0

  log "確認"

  zsh -fic '
    source "$HOME/.zshenv" 2>/dev/null || true

    [[ -r "${ZDOTDIR:-}/.zprofile" ]] && source "$ZDOTDIR/.zprofile" 2>/dev/null || true
    [[ -r "${ZDOTDIR:-}/.zshrc" ]] && source "$ZDOTDIR/.zshrc" 2>/dev/null || true

    echo "ZDOTDIR=${ZDOTDIR:-}"
    command -v zsh || true
    command -v starship || true
    command -v fzf || true
    command -v zoxide || true
    command -v direnv || true
    command -v eza || true
    type ls || true
  ' || true
}

main() {
  log "repo: $SCRIPT_DIR"
  log "target home: $TARGET_HOME"
  log "mode: $MODE"

  if [[ "$INSTALL_DEPS" -eq 1 ]]; then
    install_deps
    install_starship
    install_zoxide
    install_zsh_plugins
  fi

  log "dotfiles を配置中"
  deploy_tree "$SCRIPT_DIR/home" "$TARGET_HOME"
  deploy_tree "$SCRIPT_DIR/config" "$TARGET_HOME/.config"

  if [[ "$INSTALL_VIM_PLUG" -eq 1 ]]; then
    install_vim_plug_and_plugins
  fi

  if [[ "$SET_DEFAULT_ZSH" -eq 1 ]]; then
    set_default_shell_to_zsh
  fi

  verify

  log "完了"
  log "今すぐ反映するなら: exec zsh"
  if [[ "$OS_NAME" == "Darwin" ]]; then
    log "Terminal を開き直すと default shell の変更も反映されます"
  else
    log "WSL / shell を開き直すと default shell の変更も反映されます"
  fi
}

main "$@"
