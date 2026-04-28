# dotfiles

macOS, Ubuntu, WSL で使うための個人用 dotfiles テンプレートです。`home/` 配下は `~/` に、`config/` 配下は `~/.config/` に展開します。

## Files

```text
home/.zshenv        zsh environment variables and XDG paths
home/.zprofile      login shell setup, PATH, editor, GPG, macOS-specific hooks
home/.zshrc         interactive zsh setup, completion, aliases, language tools
home/.vimrc         Vim settings and plugins
config/starship.toml
                    Starship prompt settings
```

## Install

既存ファイルがある場合は `~/.dotfiles-backup/<timestamp>/` に退避してから展開します。まず dry-run で確認してください。

```sh
git clone git@github.com:dolmiaz/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run
./install.sh
```

デフォルトは symlink 展開です。実体コピーしたい場合は `--copy` を使います。

```sh
./install.sh --copy
```

テスト用に別ディレクトリへ展開する場合は `DOTFILES_TARGET_HOME` を指定します。

```sh
DOTFILES_TARGET_HOME=/tmp/dotfiles-home ./install.sh --dry-run
```

## Requirements

最低限必要なものは `zsh`, `git`, `vim` です。以下は入っていれば設定が有効になります。

- `starship`
- `fzf`
- `zoxide`
- `direnv`
- `eza`
- `rbenv`
- `nvm`
- `conda`

macOS では Homebrew が `/opt/homebrew` または `/usr/local` にある場合、自動で PATH に反映します。Ubuntu / WSL では各ツールを apt, Homebrew on Linux, mise, asdf など好みの方法で入れてください。

## Notes

- このリポジトリには秘密情報を置かないでください。
- `.env`, `secrets/`, `private/`, SSH keys, VPN files, history files は `.gitignore` で除外しています。
- 環境固有の設定や公開したくない設定は、別ファイルで管理するか `.gitignore` 済みの `local/` 配下に置いてください。
- 既存ファイルを戻す場合は、`~/.dotfiles-backup/<timestamp>/` から手動で戻してください。

## Update

symlink 展開している場合は、リポジトリを更新すると設定にも反映されます。

```sh
cd ~/dotfiles
git pull
```
