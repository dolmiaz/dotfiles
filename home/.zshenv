# ~/.zshenv
#
# Keep the only zsh file that zsh must read from $HOME small, then load the
# real XDG-based configuration from ~/.config/zsh.

export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

if [[ -r "$ZDOTDIR/.zshenv" ]]; then
  source "$ZDOTDIR/.zshenv"
fi
