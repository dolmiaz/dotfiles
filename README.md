# dotfiles

macOS / Ubuntu / WSL で使う個人用 dotfiles です。ホーム直下に置く必要がある最小限の shim だけを `home/` に置き、それ以外はできるだけ XDG Base Directory に寄せて `config/` で管理します。

## 構成

```text
home/
  .zshenv                    ~/.zshenv から ~/.config/zsh/.zshenv を読む shim
  .vimrc                     ~/.config/vim/vimrc を読む Vim 用 shim

config/
  zsh/.zshenv                XDG_*、履歴、npm、言語ツールなどの環境変数
  zsh/.zprofile              ログインシェル用の PATH、Homebrew、EDITOR、GPG 設定
  zsh/.zshrc                 補完、履歴、alias、fzf、zoxide、direnv、starship など
  vim/vimrc                  Vim 設定と plugin 設定
  git/ignore                 global gitignore
  npm/npmrc                  npm user config
  prettier/prettierrc        Prettier 設定
  prettier/prettierignore    Prettier ignore
  latexmk/latexmkrc          latexmk 設定
  vscode/setting.json        VS Code user settings
  starship.toml              Starship prompt
```

## インストール

まず dry-run で変更内容を確認します。

```sh
git clone git@github.com:dolmiaz/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run
./install.sh
```

デフォルトでは symlink を作ります。既存ファイルや既存 symlink がある場合は、上書きせず `~/.dotfiles-backup/<timestamp>/` に退避してから配置します。

実体コピーで配置したい場合:

```sh
./install.sh --copy
```

別のホームディレクトリ相当に展開したい場合:

```sh
DOTFILES_TARGET_HOME=/tmp/dotfiles-home ./install.sh --dry-run
DOTFILES_TARGET_HOME=/tmp/dotfiles-home ./install.sh
```

バックアップ先を明示したい場合:

```sh
DOTFILES_BACKUP_DIR=/tmp/dotfiles-backup ./install.sh
```

## install.sh の動き

- `home/` 配下のファイルを `$HOME/` に配置します。
- `config/` 配下のファイルを `$HOME/.config/` に配置します。
- `.DS_Store` は配置対象から除外します。
- 同じ symlink が既にある場合は何もしません。
- 旧構成でこのリポジトリの `home/.zprofile` / `home/.zshrc` を指していた symlink が残っている場合は、バックアップへ移動します。

## 前提ツール

最低限あるとよいもの:

- `zsh`
- `git`
- `vim`

設定内で存在すれば使うもの:

- `starship`
- `fzf`
- `zoxide`
- `direnv`
- `eza`
- `rbenv`
- `nvm`
- `conda`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`

macOS では Homebrew が `/opt/homebrew` または `/usr/local` にあれば PATH に反映します。Ubuntu / WSL では apt、Homebrew on Linux、mise、asdf など、環境に合う方法で必要なツールを入れてください。

## 更新

symlink で配置している場合は、リポジトリを更新すると設定にも反映されます。

```sh
cd ~/dotfiles
git pull
```
