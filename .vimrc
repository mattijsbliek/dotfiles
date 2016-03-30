" vim:fdm=marker

" Vundle plugins {{{

" This must be first, because it changes other options as side effect
set nocompatible
filetype off " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required

"Plugin 'airblade/vim-gitgutter'
Plugin 'bling/vim-airline'
Plugin 'cakebaker/scss-syntax.vim'
Plugin 'christoomey/vim-sort-motion'
Plugin 'ctrlpvim/ctrlp.vim'
"Plugin 'dhruvasagar/vim-vinegar'
Plugin 'elzr/vim-json'
Plugin 'ervandew/supertab'
Plugin 'gmarik/Vundle.vim'
Plugin 'godlygeek/tabular'
Plugin 'honza/vim-snippets'
Plugin 'jazzcore/ctrlp-cmatcher'
"Plugin 'kchmck/vim-coffee-script'
Plugin 'moll/vim-bbye'
Plugin 'pangloss/vim-javascript'
"Plugin 'rizzatti/dash.vim'
Plugin 'rking/ag.vim'
Plugin 'rstacruz/vim-ultisnips-css'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'SirVer/ultisnips'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-surround'
"Plugin 'vim-scripts/gitignore'
Plugin 'YankRing.vim'
Plugin 'zirrostig/vim-schlepp'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on
" required
" To ignore plugin indent changes, instead use:
"filetype plugin on

" }}}
" Plugin configuration {{{

" let g:gitgutter_sign_column_always = 1

" make all sorts case insensitive and remove duplicates.
 let g:sort_motion_flags = "ui"

" Don't fold markdown
" let g:vim_markdown_folding_disabled=1

" Stuff for CtrlP
let g:ctrlp_custom_ignore = {
	\ 'dir': 'dist\|node_modules\|bower_components\|\.git$\|build',
	\ 'file': '\.DS_Store'
	\ }
let g:ctrlp_max_files = 10000
let g:ctrlp_show_hidden = 1
let g:ctrlp_match_func = {'match' : 'matcher#cmatch' }

" Stuff for Vim Airline plugin
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#tabline#show_tab_nr = 1
let g:airline#extensions#tabline#buffer_nr_show = 1

function! AirLineMattijs()
  function! Modified()
    return &modified ? " +" : ''
  endfunction

  call airline#parts#define_raw('filename', '%<%f')
  call airline#parts#define_function('modified', 'Modified')

  let g:airline_section_b = airline#section#create_left(['filename'])
  let g:airline_section_c = airline#section#create([''])
  let g:airline_section_gutter = airline#section#create(['modified', '%='])
  let g:airline_section_x = airline#section#create_right([''])
  let g:airline_section_y = airline#section#create_right(['%c'])
  let g:airline_section_z = airline#section#create(['branch'])
endfunction

" Use scss_lint for syntax checking
let g:syntastic_scss_checkers = ['scss_lint']
let g:syntastic_php_checkers = ['php']
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_html_checkers=[]

 "Ignore unrecognized html tags
let g:syntastic_html_tidy_ignore_errors = ['Unnecessary parent selector', 'proprietary attribute', 'missing </a>', 'trimming empty', 'is not recognized', 'discarding unexpected'  ]
let g:syntastic_php_ignore_errors = ['Line indented incorrectly']

 "UtilSnips
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"
let g:UltiSnipsEditSplit="vertical"

" }}}
" Vim config options {{{

" Turn on syntax highlighting
syntax on

" Use bash for vim
set shell=/bin/bash

" Launch in fullscreen mode
"set fu

" Hide buffers instead of closing them
set hidden

" Open new windows on the right or bottom
set splitright
set splitbelow

" Improves redrawing
set ttyfast

" Visual autocomplete for command menu
set wildmenu

" Set color theme and background
colorscheme kalisi
set background=dark

" Turn off blinking cursor in normal mode
set gcr=n:blinkon0

" Set terminal to 256 colors
set t_Co=256

" Enable line highlight
set cursorline

" Set the column width to 100 character
set textwidth=0
set colorcolumn=+1

" Set styling default
set guifont=CamingoCode:h16

" Show relative line numbers
set relativenumber

" Absolute line number for the current line
set number

" Do not wrap lines
set nowrap

" Disable wrap margin
set wrapmargin=0

" Disable backups
set nobackup

" Disable swap files
set noswapfile

" Make Vim autoread changed files
set autoread

" Count underscores as a word
set iskeyword-=_

" Do not count # as a word
set iskeyword+=\#

" Do not count $ as a word
set iskeyword+=\$

" Share clipboard with the OS
set clipboard=unnamed

" Set encoding to UTF-8
set encoding=utf-8

" Scroll when reaching the top or bottom x lines
set scrolloff=5

" Don't know what this does...
set fileformat=unix

" Indentation settings
set linebreak
set tabstop=4
set shiftwidth=4
set autoindent
set copyindent
set preserveindent
set smartindent

set laststatus=2
set ttimeoutlen=50

" Prevent zero leading numbers to be interpreted as octal
set nrformats=hex

" Ignore case for searches
set ignorecase

" When you do type an uppercase character, switch to case sensitive search
set smartcase

" Applies substitutions globally on lines
set gdefault

" The lines below work together to highlight search results (as you type)
set hlsearch
set incsearch
set showmatch

" Remember more commands and search history
set history=1000

" Use many muchos levels of undo
set undolevels=1000

" Don't beep
set noerrorbells

" Set the styles for the git diff SignColumn
"highlight clear SignColumn
"highlight SignColumn guibg=#333333
"highlight GitGutterRemove guibg=#333333 guifg=#ff0000
"highlight GitGutterAdd guibg=#333333 guifg=#BCD42A

" }}}
" Mappings {{{

" Leader key to ,
let mapleader = ","

" Remap : to ;
nnoremap ; :

" Remap ; to :
nnoremap : ;

" Skip ; and insert space
imap § <ESC>f;a<space>

" Move up and down half screens
nnoremap <C-j> <C-d>
nnoremap <C-k> <C-u>

" Move in visual lines instead of actual lines
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" Map Yankring to ,p
nnoremap <silent> <leader>p :YRShow<CR>

" Move to next/prev quickfix buffer
nnoremap <silent> <up> :cprev<CR>
nnoremap <silent> <down> :cnext<CR>

" Move blocks of text around in visual mode
vmap <down>  <Plug>SchleppDown
vmap <up>    <Plug>SchleppUp

" Open scratchpad.md
noremap <leader>sp :split ~/OwnCloud/Documents/Scratchpad.md<CR>

" Edit .vimrc with leader ev
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>

" Save and source .vimrc with leader sv
nnoremap <leader>sv :so $MYVIMRC<cr>

" Edit .bash_profile with leader eb
nnoremap <leader>eb <C-w><C-v><C-l>:e ~/.bash_profile<cr>

" Edit config.fish with leader ef
nnoremap <leader>ef <C-w><C-v><C-l>:e ~/.config/fish/config.fish<cr>

" Edit vhosts with leader evh
nnoremap <leader>evh <C-w><C-v><C-l>:e /etc/apache2/extra/httpd-vhosts.conf<cr>

" Edit hosts with leader eh
nnoremap <leader>eh <C-w><C-v><C-l>:e /etc/hosts<cr>

" Save file with sudo
cmap w!! w !sudo tee % >/dev/null

" Look up in Dash documentation
"nmap <silent> <leader>k <Plug>DashSearch

" Split lines
nnoremap S i<cr><esc>^mwgk:silent! s/\v +$//<cr>:noh<cr>`w
"
" Go to previous buffer
nnoremap <D-[> :bp<CR>

" Go to next buffer
nnoremap <D-]> :bn<CR>

" turns off default regex characters and makes searches use normal regexes
nnoremap / /\v
vnoremap / /\v

" Move to beginning and end of line with H and L
onoremap H ^
noremap H ^
noremap L $

" Get rid of search highlights with , space
noremap <silent> <leader><space> :noh<CR>

" Open new split window with , w and focus on it
noremap <leader>w <C-w>v<C-w>l

" Map Ag search to ,f
noremap <leader>f :Ag -Qi

" Keep search matches in the middle of the window
"nnoremap n nzzzv
"nnoremap N Nzzzv

" Leader key + n for NERDTreeToggle
noremap <leader>n :NERDTreeToggle<CR>

" Leader key + c to go to current file in NERDTree
noremap <leader>c :NERDTreeFind<CR>

" Leader key + m for CtrlP
noremap <silent> <leader>m :CtrlP<CR>

" Leader key + j to open CtrlP in buffer mode
noremap <silent> <leader>j :CtrlPBuffer<CR>

" Set filetype to html
nnoremap <leader>fth :set ft=html<CR>

" Set filetype to php
nnoremap <leader>ftp :set ft=php<CR>

" RenameFile taken from https://github.com/r00k/dotfiles/blob/master/vimrc
function! RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'), 'file')
    if new_name != '' && new_name != old_name
	exec ':saveas ' . new_name
	exec ':silent !rm ' . old_name
	redraw!
    endif
endfunction

noremap <Leader>r :call RenameFile()<cr>

" Quickly switch buffer with <leader> #
" E.g. ,2 will switch to buffer 2
for i in range(1, 99)
    execute printf('nnoremap <Leader>%d :%db<CR>', i, i)
endfor

" Quickly delete buffers with <leader>d #
" E.g. ,d2 will delete buffer #2
for i in range(1, 99)
    execute printf('nnoremap <silent> <Leader>d%d :Bdelete %d<CR>', i, i)
endfor

" Create snippet
vnoremap <C-s> :call CreateSnippet()<cr>

function! CreateSnippet()
    let txt = s:get_visual_selection()
    let snippetId = substitute(txt, " ", "_", "g")
    let defaultTxt = input("What's the default text? ")
    if strlen(defaultTxt) == 0
	return
    endif
    let defaultLocale = input("What's the default locale? (nl) ")
    if strlen(defaultLocale) == 0
	let defaultLocale = "nl"
    endif
    if strlen(txt) == 0
	echom "No text selected"
	return
    endif
    execute ":write"
    execute ":edit application/configs/snippets.ini"
    execute "/\\\v\\\[staging\\\ :\\\ production\\\]"
    execute "normal! Osnippets." . snippetId . ".has_text = 1"
    execute "normal! osnippets." . snippetId . ".text." . defaultLocale . " = \"" . defaultTxt . "\""
    execute "normal! o"
    execute ":nohl"
    execute ":write"
    execute ":b#"
endfunction

" Create snippets from selected text
function! s:get_visual_selection()
	  " Why is this not a built-in Vim script function?!
      let [lnum1, col1] = getpos("'<")[1:2]
      let [lnum2, col2] = getpos("'>")[1:2]
      let lines = getline(lnum1, lnum2)
      let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
      let lines[0] = lines[0][col1 - 1:]
      return join(lines, "\n")
endfunction

" }}}
" Auto commands {{{

" Set indentation for js files
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

" Set different column width for git commits and phtml
augroup textwidth
	autocmd!
	autocmd FileType gitcommit setlocal textwidth=72
	autocmd BufRead *.phtml,*.html,.vimrc,.bash_profile setlocal textwidth=0
augroup END

" Clear all open buffer while keeping windows intact
if !exists(":ClearBuffers")
    command ClearBuffers bufdo :Bdelete
endif

" Save when losing focus, ignore errors
au FocusLost * silent! wa 

" Set markdown filetype
au BufRead,BufNewFile *.md set filetype=markdown

" Set scss filetype
autocmd BufRead,BufNewFile *.scss set filetype=scss.css

" Set json filetype
au BufRead,BufNewFile *.json set filetype=json

autocmd Vimenter * call AirLineMattijs()

" }}}
