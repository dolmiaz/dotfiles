#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
TARGET_HOME=${DOTFILES_TARGET_HOME:-${HOME:-}}
TARGET_HOME=${TARGET_HOME%/}
MODE=link
DRY_RUN=0
BACKUP_ROOT=${DOTFILES_BACKUP_DIR:-}

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [--dry-run] [--copy]

Options:
  --dry-run   Print the planned changes without writing files.
  --copy      Copy files instead of creating symbolic links.
  -h, --help  Show this help.

Environment:
  DOTFILES_TARGET_HOME  Install destination. Defaults to $HOME.
  DOTFILES_BACKUP_DIR   Backup destination for replaced files.
EOF
}

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: $*"
  else
    "$@"
  fi
}

relative_to_target_home() {
  path=$1
  rel=${path#"$TARGET_HOME"/}

  if [ "$rel" = "$path" ]; then
    rel=$(basename "$path")
  fi

  printf '%s\n' "$rel"
}

ensure_backup_root() {
  if [ -z "$BACKUP_ROOT" ]; then
    BACKUP_ROOT=$TARGET_HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)
  fi
}

backup_path() {
  target=$1
  rel=$(relative_to_target_home "$target")
  printf '%s/%s\n' "$BACKUP_ROOT" "$rel"
}

backup_existing() {
  target=$1

  ensure_backup_root
  destination=$(backup_path "$target")
  destination_dir=$(dirname "$destination")

  run mkdir -p "$destination_dir"
  log "backup: $target -> $destination"

  if [ "$DRY_RUN" -eq 0 ]; then
    mv "$target" "$destination"
  fi
}

is_same_link() {
  target=$1
  source=$2

  [ -L "$target" ] || return 1
  [ "$(readlink "$target")" = "$source" ]
}

replace_target_if_needed() {
  target=$1
  source=$2

  if [ "$MODE" = link ] && is_same_link "$target" "$source"; then
    log "skip: $target"
    return 1
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup_existing "$target"
  fi

  return 0
}

install_file() {
  source=$1
  target=$2
  target_dir=$(dirname "$target")

  run mkdir -p "$target_dir"

  if ! replace_target_if_needed "$target" "$source"; then
    return 0
  fi

  if [ "$MODE" = link ]; then
    run ln -s "$source" "$target"
    log "link: $target -> $source"
  else
    run cp -p "$source" "$target"
    log "copy: $source -> $target"
  fi
}

should_skip_source() {
  source=$1

  case $(basename "$source") in
    .DS_Store)
      return 0
      ;;
  esac

  return 1
}

install_tree() {
  source_root=$1
  target_root=$2

  [ -d "$source_root" ] || fail "missing source directory: $source_root"

  find "$source_root" -type f | sort | while IFS= read -r source; do
    if should_skip_source "$source"; then
      log "skip: $source"
      continue
    fi

    rel=${source#"$source_root"/}
    install_file "$source" "$target_root/$rel"
  done
}

remove_legacy_repo_link() {
  rel=$1
  target=$TARGET_HOME/$rel
  legacy_source=$SCRIPT_DIR/home/$rel

  if is_same_link "$target" "$legacy_source"; then
    backup_existing "$target"
    log "legacy: moved old home link $target"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --copy)
      MODE=copy
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac

  shift
done

[ -n "$TARGET_HOME" ] || fail "DOTFILES_TARGET_HOME or HOME is empty"
[ -d "$SCRIPT_DIR/home" ] || fail "missing home directory: $SCRIPT_DIR/home"
[ -d "$SCRIPT_DIR/config" ] || fail "missing config directory: $SCRIPT_DIR/config"

log "target home: $TARGET_HOME"
log "mode: $MODE"

if [ "$DRY_RUN" -eq 1 ]; then
  log "dry-run: enabled"
fi

run mkdir -p "$TARGET_HOME"

remove_legacy_repo_link ".zprofile"
remove_legacy_repo_link ".zshrc"

install_tree "$SCRIPT_DIR/home" "$TARGET_HOME"
install_tree "$SCRIPT_DIR/config" "$TARGET_HOME/.config"

log "done"
