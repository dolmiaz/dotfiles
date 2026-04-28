set encoding=utf-8
scriptencoding utf-8

"----------------------------------------------------------
" Leader
"----------------------------------------------------------

let mapleader = "\<Space>"
let maplocalleader = "\<Space>"

"----------------------------------------------------------
" vim-plug
"----------------------------------------------------------

call plug#begin('~/.vim/plugged')

" カラースキーム
Plug 'tomasr/molokai'

" ステータスライン
Plug 'itchyny/lightline.vim'

" 末尾の空白をハイライト
Plug 'bronson/vim-trailing-whitespace'

" インデント可視化
Plug 'Yggdroot/indentLine'

" オートセーブ
Plug 'vim-scripts/vim-auto-save'

" ファイルツリー
Plug 'preservim/nerdtree'

" あいまいファイル検索
Plug 'ctrlpvim/ctrlp.vim'

" 括弧・引用符・タグ操作
Plug 'tpope/vim-surround'

" コメントアウト
Plug 'tpope/vim-commentary'

" Git差分表示
Plug 'airblade/vim-gitgutter'

" .editorconfig対応
Plug 'editorconfig/editorconfig-vim'

" Vim 8以上ならALE、古いVimならSyntastic
if v:version >= 800
    Plug 'dense-analysis/ale'
else
    Plug 'vim-syntastic/syntastic'
endif

call plug#end()

"----------------------------------------------------------
" 文字コード / 改行コード
"----------------------------------------------------------

set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,euc-jp,cp932
set fileformats=unix,dos,mac
set ambiwidth=double

"----------------------------------------------------------
" インデント
"----------------------------------------------------------

set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent

"----------------------------------------------------------
" 検索
"----------------------------------------------------------

set incsearch
set ignorecase
set smartcase
set hlsearch

" ESCキー2度押しで検索ハイライト解除
nnoremap <silent> <Esc><Esc> :<C-u>nohlsearch<CR>

"----------------------------------------------------------
" 表示
"----------------------------------------------------------

set number
set cursorline
set showmatch
set title
set display+=lastline
set scrolloff=5
set sidescrolloff=5

if exists('&signcolumn')
    set signcolumn=yes
endif

"----------------------------------------------------------
" 移動
"----------------------------------------------------------

" 折り返し行では表示行単位で移動する
" ただし 5j のように回数指定した場合は通常の行移動にする
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
nnoremap <expr> <Down> v:count == 0 ? 'gj' : 'j'
nnoremap <expr> <Up> v:count == 0 ? 'gk' : 'k'

"----------------------------------------------------------
" 編集
"----------------------------------------------------------

set backspace=indent,eol,start
set hidden
set autoread
set confirm

" ビープ音を消す
set visualbell
set t_vb=

if exists('&belloff')
    set belloff=all
endif

"----------------------------------------------------------
" クリップボード
"----------------------------------------------------------

if has('clipboard')
    set clipboard+=unnamed
    if has('unnamedplus')
        set clipboard+=unnamedplus
    endif
endif

"----------------------------------------------------------
" コマンド補完 / 履歴
"----------------------------------------------------------

set wildmenu
set wildmode=list:longest,full
set history=5000

set wildignore+=*.o,*.obj,*.pyc,*.class,*.swp
set wildignore+=*/.git/*,*/node_modules/*,*/dist/*,*/build/*

set completeopt=menuone,noinsert,noselect

" CursorHoldやGitGutter/ALEの反応を少し速くする
set updatetime=300

" キーマッピングの待ち時間を短くする
set timeoutlen=500
set ttimeoutlen=10

" 日本語ヘルプが入っている場合は日本語優先
set helplang=ja,en

"----------------------------------------------------------
" マウス
"----------------------------------------------------------

if has('mouse')
    set mouse=a

    if exists('&ttymouse')
        if has('mouse_sgr')
            set ttymouse=sgr
        elseif v:version > 703 || v:version == 703 && has('patch632')
            set ttymouse=sgr
        else
            set ttymouse=xterm2
        endif
    endif
endif

"----------------------------------------------------------
" xterm paste
"----------------------------------------------------------

if &term =~ "xterm"
    let &t_SI .= "\e[?2004h"
    let &t_EI .= "\e[?2004l"
    let &pastetoggle = "\e[201~"

    function! XTermPasteBegin(ret)
        set paste
        return a:ret
    endfunction

    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
endif

"----------------------------------------------------------
" matchit
"----------------------------------------------------------

runtime macros/matchit.vim

"----------------------------------------------------------
" ファイルタイプ別設定
"----------------------------------------------------------

augroup vimrc_filetype_settings
    autocmd!
    autocmd FileType python setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
    autocmd FileType javascript,typescript,json,html,css,scss,yaml setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
    autocmd FileType make setlocal noexpandtab
    autocmd FileType markdown setlocal wrap linebreak
augroup END

"----------------------------------------------------------
" キーマッピング
"----------------------------------------------------------

" vimrcをすぐ開く / 再読み込み
nnoremap <silent> <Leader>ev :<C-u>edit $MYVIMRC<CR>
nnoremap <silent> <Leader>sv :<C-u>source $MYVIMRC<CR>

" 保存・終了
nnoremap <silent> <Leader>w :<C-u>update<CR>
nnoremap <silent> <Leader>q :<C-u>quit<CR>

" バッファ移動
nnoremap <silent> <Leader>bn :<C-u>bnext<CR>
nnoremap <silent> <Leader>bp :<C-u>bprevious<CR>
nnoremap <silent> <Leader>bd :<C-u>bdelete<CR>

" ウィンドウ移動
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ウィンドウ分割
nnoremap <silent> <Leader>ss :<C-u>split<CR>
nnoremap <silent> <Leader>vs :<C-u>vsplit<CR>

" Quickfix
nnoremap <silent> [q :<C-u>cprevious<CR>
nnoremap <silent> ]q :<C-u>cnext<CR>
nnoremap <silent> <Leader>co :<C-u>copen<CR>
nnoremap <silent> <Leader>cc :<C-u>cclose<CR>

" ビジュアルモードで貼り付けた時、無名レジスタを上書きしない
xnoremap p "_dP

"----------------------------------------------------------
" Undo / Swap / Backup
"----------------------------------------------------------

let s:cache_root = expand('~/.vim/cache')

for s:dir in ['backup', 'swap', 'undo']
    if !isdirectory(s:cache_root . '/' . s:dir)
        call mkdir(s:cache_root . '/' . s:dir, 'p')
    endif
endfor

" バックアップファイルを専用ディレクトリへ
set backup
set writebackup
execute 'set backupdir=' . fnameescape(s:cache_root . '/backup') . '//'

" swapファイルを専用ディレクトリへ
execute 'set directory=' . fnameescape(s:cache_root . '/swap') . '//'

" 永続Undo
if has('persistent_undo')
    execute 'set undodir=' . fnameescape(s:cache_root . '/undo') . '//'
    set undofile
endif

unlet s:dir
unlet s:cache_root

"----------------------------------------------------------
" カラースキーム / syntax
"----------------------------------------------------------

set t_Co=256

if has('termguicolors')
    set termguicolors
endif

syntax enable

" 初回PlugInstall前でもエラーにしない
silent! colorscheme molokai

" 背景色を半透明にする
highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE
highlight SpecialKey ctermbg=NONE guibg=NONE
highlight EndOfBuffer ctermbg=NONE guibg=NONE

"----------------------------------------------------------
" ステータスライン
"----------------------------------------------------------

set laststatus=2
set showcmd
set ruler
set noshowmode

"----------------------------------------------------------
" lightline
"----------------------------------------------------------

let g:lightline = {
    \ 'colorscheme': 'molokai',
    \ }

"----------------------------------------------------------
" indentLine
"----------------------------------------------------------

let g:indentLine_char = '┆'
let g:indentLine_setConceal = 0
let g:indentLine_fileTypeExclude = ['help', 'nerdtree']

"----------------------------------------------------------
" CtrlP
"----------------------------------------------------------

let g:ctrlp_map = '<C-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'

let g:ctrlp_custom_ignore = {
    \ 'dir': '\v[\/](\.git|node_modules|dist|build|vendor)$',
    \ 'file': '\v\.(o|obj|pyc|class|swp)$',
    \ }

nnoremap <silent> <Leader>ff :<C-u>CtrlP<CR>
nnoremap <silent> <Leader>fb :<C-u>CtrlPBuffer<CR>
nnoremap <silent> <Leader>fm :<C-u>CtrlPMRUFiles<CR>

"----------------------------------------------------------
" NERDTree
"----------------------------------------------------------

nnoremap <silent> <Leader>nt :<C-u>NERDTreeToggle<CR>

let NERDTreeShowHidden = 1
let NERDTreeIgnore = ['\.pyc$', '\.o$', '\.class$', 'node_modules']

"----------------------------------------------------------
" vim-gitgutter
"----------------------------------------------------------

let g:gitgutter_enabled = 1
let g:gitgutter_map_keys = 0

nnoremap <silent> ]h :<C-u>GitGutterNextHunk<CR>
nnoremap <silent> [h :<C-u>GitGutterPrevHunk<CR>
nnoremap <silent> <Leader>hp :<C-u>GitGutterPreviewHunk<CR>
nnoremap <silent> <Leader>hu :<C-u>GitGutterUndoHunk<CR>


"----------------------------------------------------------
" ALE
"----------------------------------------------------------

if v:version >= 800
    let g:ale_linters = {
        \ 'javascript': ['eslint'],
        \ 'typescript': ['eslint'],
        \ }

    let g:ale_fixers = {
        \ 'c': ['clang-format', 'remove_trailing_lines', 'trim_whitespace'],
        \ 'cpp': ['clang-format', 'remove_trailing_lines', 'trim_whitespace'],
        \ 'rust': ['rustfmt', 'remove_trailing_lines', 'trim_whitespace'],
        \ 'python': ['isort', 'black', 'remove_trailing_lines', 'trim_whitespace'],
        \ 'javascript': ['eslint', 'remove_trailing_lines', 'trim_whitespace'],
        \ 'typescript': ['eslint', 'remove_trailing_lines', 'trim_whitespace'],
        \ '*': ['remove_trailing_lines', 'trim_whitespace'],
        \ }

    let g:ale_lint_on_text_changed = 'normal'
    let g:ale_lint_on_insert_leave = 1
    let g:ale_lint_on_save = 1

    " 保存時に自動整形しない。手動で実行する
    let g:ale_fix_on_save = 0

    nnoremap <silent> <Leader>an :<C-u>ALENext<CR>
    nnoremap <silent> <Leader>ap :<C-u>ALEPrevious<CR>
    nnoremap <silent> <Leader>af :<C-u>ALEFix<CR>

    " format: 現在のfiletypeに応じて整形
    nnoremap <silent> <Leader>cf :<C-u>ALEFix<CR>
endif

"----------------------------------------------------------
" Syntastic
"----------------------------------------------------------

if v:version < 800
    " 構文エラー行に「>>」を表示
    let g:syntastic_enable_signs = 1

    " 他のVimプラグインと競合するのを防ぐ
    let g:syntastic_always_populate_loc_list = 1

    " 構文エラーリストを非表示
    let g:syntastic_auto_loc_list = 0

    " ファイルを開いた時に構文エラーチェックを実行する
    let g:syntastic_check_on_open = 1

    " 「:wq」で終了する時も構文エラーチェックする
    let g:syntastic_check_on_wq = 1

    " JavaScript用。構文エラーチェックにESLintを使用
    let g:syntastic_javascript_checkers = ['eslint']

    " JavaScript以外は構文エラーチェックをしない
    let g:syntastic_mode_map = {
        \ 'mode': 'passive',
        \ 'active_filetypes': ['javascript'],
        \ 'passive_filetypes': [],
        \ }
endif

"----------------------------------------------------------
" auto-save
"----------------------------------------------------------

let g:auto_save = 1
let g:auto_save_in_insert_mode = 0

