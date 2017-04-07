" vim:fdm=marker
" Vundle plugins {{{

" This must be first, because it changes other options as side effect
set nocompatible
filetype off " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" Staples
Plugin 'vim-airline/vim-airline'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-repeat'
Plugin 'scrooloose/nerdcommenter'
Plugin 'YankRing.vim'
Plugin 'tpope/vim-sleuth'
Plugin 'neomake/neomake'
Plugin 'rking/ag.vim'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'jazzcore/ctrlp-cmatcher'
Plugin 'scrooloose/nerdtree'
Plugin 'rizzatti/dash.vim'
Plugin 'tpope/vim-surround'

" Language specific
Plugin 'kewah/vim-stylefmt'
Plugin 'cakebaker/scss-syntax.vim'
Plugin 'pangloss/vim-javascript' " JS syntax highlighting
Plugin 'mxw/vim-jsx' " JSX syntax highlighting
Plugin 'elzr/vim-json'
Plugin 'flowtype/vim-flow'
Plugin 'mustache/vim-mustache-handlebars'

" Autocompletion
Plugin 'rstacruz/vim-ultisnips-css'
Plugin 'ervandew/supertab'
Plugin 'SirVer/ultisnips'
Plugin 'jiangmiao/auto-pairs'
Plugin 'alvan/vim-closetag'

" Nice to haves
Plugin 'christoomey/vim-sort-motion'
Plugin 'godlygeek/tabular'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'moll/vim-bbye'
Plugin 'zirrostig/vim-schlepp'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on
" required
" To ignore plugin indent changes, instead use:
"filetype plugin on

" }}}
" Plugin configuration {{{

" make all sorts case insensitive and remove duplicates.
let g:sort_motion_flags = "ui"

" Don't fold markdown
" let g:vim_markdown_folding_disabled=1

" Stuff for CtrlP
let g:ctrlp_custom_ignore = {
	\ 'dir': 'dist\|vendor\|node_modules\|bower_components\|\.git$\|build',
	\ 'file': '\.DS_Store'
	\ }
let g:ctrlp_max_files = 10000
let g:ctrlp_show_hidden = 1
let g:ctrlp_match_func = {'match' : 'matcher#cmatch' }
let g:ctrlp_map = '<leader>m'

" Stuff for Vim Airline plugin
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#tabline#enabled = 0
let g:airline#extensions#tabline#show_tab_nr = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#neomake#enabled = 1

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

" Set syntax checkers
let g:neomake_javascript_enabled_makers = ['eslint', 'flow']
let g:neomake_jsx_enabled_makers = ['eslint', 'flow']
let g:neomake_css_enabled_makers = ['stylelint']

" Also allow JSX syntax highlighting in .js files
let g:jsx_ext_required = 0

" Do not run vim-flow on save. Neomake still runs Flow on save.
let g:flow#enable = 0

" Close tags for filetypes
let g:closetag_filenames = "*.html,*.jsx,*.tpl"

 "UtilSnips
"let g:UltiSnipsExpandTrigger="<tab>"
"let g:UltiSnipsJumpForwardTrigger="<c-j>"
"let g:UltiSnipsJumpBackwardTrigger="<c-k>"
"let g:UltiSnipsEditSplit="vertical"

" }}}
" Vim config options {{{

" Turn on syntax highlighting
syntax on

" Use bash for vim
set shell=/bin/bash

" Add Mollie dashboard to path
set path+=/Users/mattijs/Sites/mollie/public/dashboard/src/

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

" Highlight the background of text that goes over the line limit
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%101v.\+/
autocmd BufNew,BufRead *.phtml,*.html,*.xml,*.md,*.sql match none

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
"set noexpandtab shiftwidth=4 tabstop=4 smartindent
"set copyindent
"set preserveindent

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

" Lookup word under cursor in Dash
nnoremap <silent> <leader>d :Dash<CR>

" Move to next/prev quickfix buffer
nnoremap <silent> <up> :cprev<CR>
nnoremap <silent> <down> :cnext<CR>

" Move blocks of text around in visual mode
vmap <down>  <Plug>SchleppDown
vmap <up>    <Plug>SchleppUp

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

" Go to next item in loclist
nnoremap <leader>e :lne<cr>

" Save file with sudo
cmap w!! w !sudo tee % >/dev/null

" Reformat with Stylefmt
nnoremap <silent> <leader>sf :Stylefmt<CR>
vnoremap <silent> <leader>sf :StylefmtVisual<CR>

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

" Save current buffer
noremap <leader>w :w!<cr>

" Open new split window with <leader>s and focus on it
noremap <leader>s <C-w>v<C-w>l

" Map Ag search to ,f
noremap <leader>f :Ag -Qi

" Keep search matches in the middle of the window
"nnoremap n nzzzv
"nnoremap N Nzzzv

" Leader key + n for NERDTreeToggle
noremap <leader>n :NERDTreeToggle<CR>

" Leader key + c to go to current file in NERDTree
noremap <leader>c :NERDTreeFind<CR>

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
"autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

" Enter opens tag
augroup tag_navigation
	autocmd!
	autocmd BufRead,BufNewFile * if &l:modifiable | nnoremap <buffer> <CR> :exec("tag ".expand("<cword>"))<CR> | endif
augroup END

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

" Set flow filetype
au BufRead,BufNewFile *.flow set filetype=javascript

autocmd Vimenter * call AirLineMattijs()

" Run Neomake when writing to file
autocmd! BufWritePost * Neomake

" }}}
