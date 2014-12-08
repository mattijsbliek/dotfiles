" This must be first, because it changes other options as side effect
set nocompatible
filetype off " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'
Plugin 'https://github.com/scrooloose/nerdtree'
Plugin 'https://github.com/ervandew/supertab'
Plugin 'https://github.com/bling/vim-airline'
Plugin 'https://github.com/ctrlpvim/ctrlp.vim'
Plugin 'https://github.com/scrooloose/nerdcommenter'
Plugin 'https://github.com/vim-scripts/gitignore'
Plugin 'airblade/vim-gitgutter'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'moll/vim-bbye'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'mxw/vim-jsx.git'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'trusktr/seti.vim'
Plugin 'elzr/vim-json'

Bundle 'rstacruz/vim-ultisnips-css'
Bundle 'cakebaker/scss-syntax.vim'
Bundle 'scrooloose/syntastic'
Bundle 'rking/ag.vim'
Bundle 'tpope/vim-fugitive'
Bundle "pangloss/vim-javascript"
Bundle 'YankRing.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on
" required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList          - list configured plugins
" :PluginInstall(!)    - install (update) plugins
" :PluginSearch(!) foo - search (or refresh cache first) for foo
" :PluginClean(!)      - confirm (or auto-approve) removal of unused plugins
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" key remapping
let mapleader = ","

" Hide buffers instead of closing them
set hidden

" Open new windows on the right or bottom
set splitright
set splitbelow

set lazyredraw              " Don't update while in macro
set ttyfast                 " Improves redrawing
set wildmenu            " visual autocomplete for command menu

" Set color theme
colorscheme peacock
"colorscheme seti

" Enable line highlight
set cursorline

" Set the column width to 100 character
set textwidth=0
set colorcolumn=+1

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

" Set different column width for git commits and phtml
augroup textwidth
	autocmd!
	autocmd FileType gitcommit setlocal textwidth=72
	autocmd BufRead *.phtml,*.html,.vimrc,.bash_profile setlocal textwidth=0
augroup END

" Jump to definitions of functions with c-tags
augroup tag_navigation
        autocmd!
        autocmd BufRead,BufNewFile * if &l:modifiable | nnoremap <buffer> <CR> :exec("tag ".expand("<cword>"))<CR> | endif
augroup END

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

" Clear all open buffer while keeping windows intact
if !exists(":ClearBuffers")
    command ClearBuffers bufdo :Bdelete
endif

" Go to previous buffer
nnoremap <D-[> :bp<CR>

" Go to next buffer
nnoremap <D-]> :bn<CR>

" Set the styles for the git diff SignColumn
highlight clear SignColumn
highlight SignColumn guibg=#333333
highlight GitGutterRemove guibg=#333333 guifg=#ff0000
highlight GitGutterAdd guibg=#333333 guifg=#BCD42A

let g:gitgutter_sign_column_always = 1
let g:CommandTMatchWindowReverse = 1

" Set styling default
set guifont=CamingoCode:h16

set relativenumber " show line numbers
set number " also set number, works for the current line
set nowrap " do not wrap lines
set wrapmargin=0 " disable wrap margin

set nobackup
set noswapfile " disable swap files
set autoread " Make Vim autoread changed files

" This lets you use w!! to save a file after you opened it already
cmap w!! w !sudo tee % >/dev/null

au FocusLost * silent! wa " save when losing focus, ignore errors

" Set markdown filetype
au BufRead,BufNewFile *.md set filetype=markdown

" Don't fold markdown
let g:vim_markdown_folding_disabled=1

" Set scss filetype
autocmd BufRead,BufNewFile *.scss set filetype=scss.css

" Set json filetype
au BufRead,BufNewFile *.json set filetype=json

set iskeyword-=_ " count underscores as a word
set iskeyword+=\$ " do not count $ as a word
set iskeyword+=\# " do not count # as a word
set clipboard=unnamed " share clipboard with the OS
set encoding=utf-8 " set encoding to UTF-8
set scrolloff=8

" Indentation settings
set linebreak
set tabstop=4
set shiftwidth=4
set autoindent
set copyindent
set preserveindent
set smartindent
set fileformat=unix


" Stuff for Vim Airline plugin
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#tabline#show_tab_nr = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

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

autocmd Vimenter * call AirLineMattijs()

set laststatus=2
set ttimeoutlen=50

" Prevent zero leading numbers to be interpreted as octal
set nrformats=hex

" turns off default regex characters and makes searches use normal regexes
nnoremap / /\v
vnoremap / /\v

set ignorecase " Ignore case for searches
set smartcase " When you do type a case, it will not be ignored
set gdefault " Applies substitutions globally on lines
" The lines below work together to highlight search results (as you type)
set hlsearch
set incsearch
set showmatch

set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set noerrorbells         " don't beep

" Use scss_lint for syntax checking
let g:syntastic_scss_checkers = ['scss_lint']

" Ignore unrecognized html tags
let g:syntastic_html_tidy_ignore_errors = [ 'trimming empty', 'is not recognized', 'discarding unexpected'  ]

" Move to beginning and end of line with H and L
onoremap H ^
noremap H ^
noremap L $

" Delete without saving into the default register
nnoremap <Leader>d "_d
nnoremap <Leader>D "_D
nnoremap <Leader>C "_C
nnoremap <Leader>c "_c
nnoremap <Leader>x "_x

" Get rid of search highlights with , space
noremap <silent> <leader><space> :noh<CR>

" Open new split window with , w and focus on it
noremap <leader>w <C-w>v<C-w>l

" Map Ag search to ,f
noremap <leader>f :Ag -Qi

" Keep search matches in the middle of the window
nnoremap n nzzzv
nnoremap N Nzzzv

" leader key + n for NERDTreeToggle
noremap <leader>n :NERDTreeToggle<CR>

" leader key + c to go to current file in NERDTree
noremap <leader>c :NERDTreeFind<CR>

" leader key + m for CtrlP
noremap <silent> <leader>m :CtrlP<CR>

" leader key + j to open CtrlP in buffer mode
noremap <silent> <leader>j :CtrlPBuffer<CR>

let g:ctrlp_custom_ignore = '_site\|node_modules\|bower_components\|\.git$\|DS_Store\|build'
let g:ctrlp_max_files = 40000
let g:ctrlp_show_hidden = 1

" remap : to ;
nnoremap ; :

" remap ; to :
nnoremap : ;

" remap jj key to <esc>
imap jj <ESC>

" Skip ; and insert space
imap § <ESC>f;a<space>

" disable arrow keys (oh God here we go)
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
nnoremap j gj
nnoremap k gk

" Map Yankring to ,p
nnoremap <silent> <leader>p :YRShow<CR>

" Edit .vimrc with leader ev
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>

" Save and source .vimrc with leader sv
nnoremap <leader>sv :so $MYVIMRC<cr>

" Edit .bash_profile with leader eb
nnoremap <leader>eb <C-w><C-v><C-l>:e ~/.bash_profile<cr>

" Edit vhosts with leader evh
nnoremap <leader>evh <C-w><C-v><C-l>:e /etc/apache2/extra/httpd-vhosts.conf<cr>

" Edit hosts with leader eh
nnoremap <leader>eh <C-w><C-v><C-l>:e /etc/hosts<cr>

" Save file with sudo
cmap w!! w !sudo tee % >/dev/null

" Move in visual lines instead of actual lines
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" Split lines
nnoremap S i<cr><esc>^mwgk:silent! s/\v +$//<cr>:noh<cr>`w

" UtilSnips
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"
let g:UltiSnipsEditSplit="vertical"
