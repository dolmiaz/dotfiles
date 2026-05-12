" ~/.vimrc
"
" Compatibility shim for Vim versions or launch paths that still look in $HOME.

let s:xdg_config_home = empty($XDG_CONFIG_HOME) ? expand('~/.config') : $XDG_CONFIG_HOME
let s:vimrc = s:xdg_config_home . '/vim/vimrc'

if filereadable(s:vimrc)
    execute 'source ' . fnameescape(s:vimrc)
endif

unlet s:vimrc
unlet s:xdg_config_home
