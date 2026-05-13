# dotfiles

Ubuntu / Debian / WSL を主対象にした個人用 dotfiles です。

`install.sh` はこのリポジトリを clone したディレクトリ内で実行する前提です。`home/` と `config/` 以下のファイルを `$HOME` と `$HOME/.config` に配置し、必要に応じて CLI ツールや Vim plugin も導入します。

## 対象環境

- Ubuntu / Debian 系環境
- WSL Ubuntu
- `sudo` が使える通常ユーザー

macOS 向けの分岐も一部設定ファイルに含みますが、依存パッケージの自動導入は `apt-get` が使える環境向けです。`apt-get` が無い場合、パッケージ導入は警告してスキップされます。

## インストール

```sh
git clone https://github.com/dolmiaz/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

デフォルトでは symlink で配置します。実体コピーで配置したい場合は `--copy` を指定します。

```sh
bash install.sh --copy
```

変更内容だけ確認する場合は `--dry-run` を使います。

```sh
bash install.sh --dry-run
```

既存ファイルがある場合は上書きせず、`~/.dotfiles-backup/YYYYmmddHHMMSS/` 以下に退避してから配置します。

## オプション

```text
bash install.sh [options]

Options:
  --link          symlink で配置する。デフォルト
  --copy          実体コピーで配置する
  --dry-run       変更内容だけ表示する
  --no-deps       apt / starship / zoxide / zsh plugin を入れない
  --no-vim-plug   vim-plug / Vim plugin を入れない
  --no-chsh       default shell を zsh に変えない
  -h, --help      ヘルプ表示
```

環境変数:

```sh
DOTFILES_TARGET_HOME=/path/to/home
DOTFILES_BACKUP_DIR=/path/to/backup
```

- `DOTFILES_TARGET_HOME`: 配置先の home directory。デフォルトは `$HOME`
- `DOTFILES_BACKUP_DIR`: 既存ファイルの退避先。デフォルトは `$HOME/.dotfiles-backup/<timestamp>`

例:

```sh
DOTFILES_TARGET_HOME="$HOME/test-home" bash install.sh --copy --no-deps --no-chsh
```

## インストールされるもの

`--no-deps` を付けない場合、次を導入します。

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

`eza` が apt 標準リポジトリに無い場合は、eza の apt repository を追加して導入します。

apt 以外で入るもの:

- `starship`
- `zoxide`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`

`zsh-autosuggestions` と `zsh-syntax-highlighting` は `/usr/local/share/` 以下に clone / update します。

`--no-vim-plug` を付けない場合、次を導入します。

- `vim-plug`
- `config/vim/vimrc` に定義された Vim plugin

`--no-chsh` を付けない場合、default shell を `zsh` に変更します。

## 配置されるファイル

リポジトリ内の配置:

```text
~/dotfiles/
  home/
    .vimrc
    .zshenv
  config/
    git/
      ignore
    latexmk/
      latexmkrc
    npm/
      npmrc
    prettier/
      prettierignore
      prettierrc
    starship.toml
    vim/
      vimrc
    vscode/
      setting.json
    zsh/
      .zprofile
      .zshenv
      .zshrc
  install.sh
```

反映先:

```text
~/.vimrc
~/.zshenv
~/.config/git/ignore
~/.config/latexmk/latexmkrc
~/.config/npm/npmrc
~/.config/prettier/prettierignore
~/.config/prettier/prettierrc
~/.config/starship.toml
~/.config/vim/vimrc
~/.config/vscode/setting.json
~/.config/zsh/.zprofile
~/.config/zsh/.zshenv
~/.config/zsh/.zshrc
```

`~/.zshenv` と `~/.vimrc` は shim です。実体の zsh / Vim 設定は XDG Base Directory に寄せて、`~/.config/zsh/` と `~/.config/vim/` から読み込みます。

## 再実行

`install.sh` は再実行できます。

- 既に同じ symlink がある場合はスキップします。
- 既存ファイルが違う場合は backup directory に退避します。
- `/usr/local/share/` 以下の zsh plugin は既存 clone があれば `git pull --ff-only` します。

設定を現在の shell にすぐ反映する場合:

```sh
exec zsh
```
