# SOURCE
# -----------------------------------------

# Git bash completion
if [ -f ~/.git-completion.bash ]; then
	source ~/.git-completion.bash
	source ~/.git-prompt.sh
	export PS1='\[\033[0;32m\]\w\e[m \n \[\033[1;35m\] $(__git_ps1) \$ \[\e[m\]'
fi


# EXPORT
# -----------------------------------------

export CLICOLOR=1
export TERM=xterm-color

# Fix C compiler for ctrlp-cmatcher (https://github.com/JazzCore/ctrlp-cmatcher/)
export CFLAGS=-Qunused-arguments
export CPPFLAGS=-Qunused-arguments

# Set PATH
export PATH=/usr/local/php5/bin:$PATH
export PATH=$PATH:/usr/local/bin:$PATH
export PATH=$PATH:/Users/mattijs/pear/bin
export PATH=$PATH:/Users/mattijs/Development/adt-bundle-mac/sdk/tools
export PATH=$PATH:/Users/mattijs/Development/adt-bundle-mac/sdk/platform-tools
export PATH=$PATH:/usr/local/share/npm/bin
export PATH=$PATH:/opt/bin
export PATH=$PATH:./vendor/bin

# Add rvm gems and nginx to the path
export PATH=$PATH:~/.gem/ruby/1.8/bin:~/.gem/ruby/2.0/bin:/opt/nginx/sbin
export PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

# Show the name of the current project in the tab
export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}\007"'

# Set locations for Homebrew Cask
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# Export application env for Garp/Golem
export APPLICATION_ENV=development

# Set NODE_ENV
export NODE_ENV=development

# Set my editor and git editor
export EDITOR="mvim -f"
export GIT_EDITOR='mvim -f'

# Default language settings
export LANGUAGE=en_US
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE="en_US.UTF-8"


# ALIAS
# -----------------------------------------

alias c='clear' # c: Clear terminal display
alias qfind="find . -name " # qfind: Quickly search for file

alias ftpstart='sudo -s launchctl load -w /System/Library/LaunchDaemons/ftp.plist'
alias ftpstop='sudo -s launchctl unload -w /System/Library/LaunchDaemons/ftp.plist'

# Git flow aliases
alias feature='g feature start'
alias release='g release start'
alias hotfix='g hotfix start'
alias publish='g feature publish'

# Reload bash profile
alias reload='source ~/.bash_profile'

# Restart apache
alias restart='sudo apachectl restart'

# MySQL on the cli
alias mysql=/usr/local/mysql/bin/mysql

# Garp and Golem aliases
alias garp='php garp/scripts/garp\.php'
alias golem='php ~/Sites/golem/scripts/golem\.php'
alias g='golem'
alias glg='sh garp/scripts/pull_changes.sh'
alias gpg='sh garp/scripts/push_changes.sh'
alias gpullcore='sh core/scripts/pull_changes.sh'
alias gpushcore='sh core/scripts/push_changes.sh'

# Composer
alias composer="/usr/local/bin/composer.phar"

# Run Homebrew CTags
alias ctags="`brew --prefix`/bin/ctags"

# Run CTags on current directory
alias retag='ctags -R --exclude=.svn --exclude=.sql --exclude=.git --exclude=log --exclude=tmp --exclude=node_modules --exclude=bower_components *'

# Map m to mvim
# Map m to mvim
alias m='mvim'

alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"

# VARIOUS
# -----------------------------------------

# Cycle through auto-complete options
bind '"\t":menu-complete'

# Add SSH keys
ssh-add ~/.ssh/id_dsa > /dev/null 2>&1
ssh-add ~/.ssh/id_rsa > /dev/null 2>&1

# Don't check mail when opening terminal.
unset MAILCHECK

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" 

if [ -f $(brew --prefix)/etc/bash_completion ]; then
	. $(brew --prefix)/etc/bash_completion
fi

# FUNCTIONS
# -----------------------------------------

# Fetch command names from library folders
# Used by _g completion script below
fetchCommands() {
        local DIR=$1
        local SUFFIX="php"
        local cmdlist=""
        if [ ! -d "$DIR" ]; then
                # Library directory not found
                return 1
        fi

        for i in "$DIR"/*.$SUFFIX
        do
                local basename=${i##*/}
                local commandname=${basename%%.$SUFFIX}
                cmdlist=$cmdlist" $commandname"
        done
        echo $cmdlist
}

# Enable TAB-completion for Garp commands
# Syntax is usually:
# g <command> <action> <args>
_g() {
        local cur prev opts base cmdlist
       COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"


        # If a command is chosen, try to complete its methods
        if [ $prev != 'g' ]; then
                cmdlist=$(echo "" | php garp/scripts/garp.php $prev --complete)
                COMPREPLY=( $(compgen -W "${cmdlist}" ${cur}) )
        else
                COMPREPLY=( $(compgen -W "${cmdlist}" ${cur}) )
        fi

        return 0
}
complete -o default -F _g g

# Finish whatever you're on: feature, hotfix or release
function finish {
	currbranch=`git branch | grep "^* "`
	currbranch=${currbranch:2}
	featureprefix=`git config gitflow.prefix.feature`
	hotfixprefix=`git config gitflow.prefix.hotfix`
	releaseprefix=`git config gitflow.prefix.release`
	if [[ "$currbranch" == $featureprefix* ]]; then
		g feature finish
	elif [[ "$currbranch" == $hotfixprefix* ]]; then
		g hotfix finish
	elif [[ "$currbranch" == $releaseprefix* ]]; then
		g release finish
	else
		echo "There's nothing to finish"
		return 1
	fi
	return 0
}

syncSvnSt() {
        addables=`svn st | grep "^?"`
        deletables=`svn st | grep "^\!"`
        if [ -n "$addables" ]; then
                svn add `svn st | grep "^?" | awk '{print $2}'`
        fi
        if [ -n "$deletables" ]; then
                svn rm `svn st | grep "^\!" | awk '{print $2}'`
        fi
}

git_set_upstream() {
    git push --set-upstream origin `git branch | grep '*' | cut -d'*' -f 2`
}
