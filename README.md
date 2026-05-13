# dotfiles

Ubuntu / Debian / WSL 向けの個人用 dotfiles と初期セットアップです。

## 対象環境

- `apt-get` が使える Ubuntu / Debian 系環境
- WSL Ubuntu

macOS 用の設定も一部含みますが、`install.sh` は `apt-get` 前提です。

## インストール

```sh
curl -fsSL https://raw.githubusercontent.com/dolmiaz/dotfiles/main/install.sh | bash
```

または clone して実行します。

```sh
git clone https://github.com/dolmiaz/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```

`install.sh` は実行ディレクトリに `setup-dotfiles.sh` を生成し、そのまま実行します。

## インストールされるもの

apt で入るもの:

- `ca-certificates`
- `curl`
- `wget`
- `git`
- `vim`
- `zsh`
- `direnv`
- `fzf`
- `gpg`
- `unzip`
- `software-properties-common`
- `eza`

apt 以外で入るもの:

- `starship`
- `zoxide`
- `vim-plug`
- Vim plugin
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`

その他の変更:

- dotfiles リポジトリを clone / update
- dotfiles を `$HOME` と `$HOME/.config` に配置
- `~/.config/latexmk/latexmkrc` を削除
- `~/.config/zsh/.zshrc` に Ubuntu / WSL 用の plugin loader を追記
- default shell を `zsh` に変更

## 配置

デフォルトではリポジトリを `~/dotfiles` に置き、dotfiles はコピーで配置します。

```text
~/dotfiles/
  home/
    .zshenv
    .vimrc
  config/
    git/config
    git/ignore
    npm/npmrc
    prettier/prettierrc
    prettier/prettierignore
    starship.toml
    vim/vimrc
    vscode/setting.json
    zsh/.zshenv
    zsh/.zprofile
    zsh/.zshrc
```

反映先:

```text
~/.zshenv
~/.vimrc
~/.config/git/config
~/.config/git/ignore
~/.config/npm/npmrc
~/.config/prettier/prettierrc
~/.config/prettier/prettierignore
~/.config/starship.toml
~/.config/vim/vimrc
~/.config/vscode/setting.json
~/.config/zsh/.zshenv
~/.config/zsh/.zprofile
~/.config/zsh/.zshrc
```

`~/.zshenv` は `~/.config/zsh/.zshenv` を読み込む shim です。zsh の実体設定は XDG Base Directory に寄せています。

## 環境変数

実行時に次の環境変数で挙動を変更できます。

```sh
DOTFILES_REPO=https://github.com/dolmiaz/dotfiles.git
DOTFILES_DIR=$HOME/dotfiles
INSTALL_MODE=copy
REMOVE_LATEXMK=1
```

- `DOTFILES_REPO`: clone するリポジトリ
- `DOTFILES_DIR`: clone 先
- `INSTALL_MODE`: `copy` または `link`
- `REMOVE_LATEXMK`: `1` なら `~/.config/latexmk/latexmkrc` を削除

例:

```sh
DOTFILES_DIR="$HOME/src/dotfiles" INSTALL_MODE=link bash install.sh
```
