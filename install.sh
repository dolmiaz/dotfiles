#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
TARGET_HOME=${DOTFILES_TARGET_HOME:-$HOME}
TARGET_HOME=${TARGET_HOME%/}
MODE=link
DRY_RUN=0
BACKUP_ROOT=${DOTFILES_BACKUP_DIR:-"$TARGET_HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)"}

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Install dotfiles into ~/.

Options:
  --dry-run   Show what would change without writing files.
  --copy      Copy files instead of creating symlinks.
  -h, --help  Show this help.

Environment:
  DOTFILES_TARGET_HOME  Override the install target home directory.
  DOTFILES_BACKUP_DIR   Override the backup directory for existing files.
EOF
}

say() {
  printf '%s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    say "dry-run: $*"
  else
    "$@"
  fi
}

backup_existing() {
  target=$1
  rel=${target#"$TARGET_HOME"/}

  if [ "$rel" = "$target" ]; then
    rel=$(basename "$target")
  fi

  backup_path=$BACKUP_ROOT/$rel
  backup_dir=$(dirname "$backup_path")

  run mkdir -p "$backup_dir"
  say "backup: $target -> $backup_path"

  if [ "$DRY_RUN" -eq 0 ]; then
    mv "$target" "$backup_path"
  fi
}

install_file() {
  source_path=$1
  target_path=$2
  target_dir=$(dirname "$target_path")

  run mkdir -p "$target_dir"

  if [ "$MODE" = "link" ] && [ -L "$target_path" ]; then
    current_target=$(readlink "$target_path")

    if [ "$current_target" = "$source_path" ]; then
      say "skip: $target_path"
      return
    fi
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    backup_existing "$target_path"
  fi

  if [ "$MODE" = "link" ]; then
    run ln -s "$source_path" "$target_path"
    say "link: $target_path -> $source_path"
  else
    run cp -p "$source_path" "$target_path"
    say "copy: $source_path -> $target_path"
  fi
}

install_tree() {
  source_root=$1
  target_root=$2

  [ -d "$source_root" ] || die "missing source directory: $source_root"

  find "$source_root" -type f | sort | while IFS= read -r source_path; do
    rel=${source_path#"$source_root"/}
    install_file "$source_path" "$target_root/$rel"
  done
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
      die "unknown option: $1"
      ;;
  esac

  shift
done

[ -n "$TARGET_HOME" ] || die "DOTFILES_TARGET_HOME or HOME is empty"

say "target home: $TARGET_HOME"
say "mode: $MODE"

if [ "$DRY_RUN" -eq 1 ]; then
  say "dry-run: enabled"
fi

install_tree "$SCRIPT_DIR/home" "$TARGET_HOME"
install_tree "$SCRIPT_DIR/config" "$TARGET_HOME/.config"

say "done"
