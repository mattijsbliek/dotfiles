# Set PATH
set -g -x PATH /usr/local/opt/coreutils/libexec/gnubin /usr/local/bin ~/.composer/vendor/bin/ /usr/local/mysql/bin /usr/local/php5/bin /usr/local/lib/node_modules ~/.rvm/bin $PATH

# Set Garp application env
set -x -g APPLICATION_ENV development

# Disable welcome message
set fish_greeting

# Add ssh keys
ssh-add ~/.ssh/id_dsa > /dev/null 2>&1
ssh-add ~/.ssh/id_rsa > /dev/null 2>&1

# Language settings
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8

# Get git branch
set fish_git_dirty_color red
set fish_git_not_dirty_color green

# Use nvm bash commands in fish
function nvm
   bass source ~/.nvm/nvm.sh ';' nvm $argv
end

# Set Caskroom symlink directory
set -x HOMEBREW_CASK_OPTS "--appdir=/Applications"

# Set prompt
function fish_prompt
    set_color normal
    echo -n (prompt_pwd)
    set -l git_branch (git rev-parse --abbrev-ref HEAD ^ /dev/null)

    if test $git_branch
        set -l git_dirty_count (git status --porcelain  | wc -l | sed "s/ //g")
        echo -n ":"
        if test $git_dirty_count -gt 0
            set_color red
        else
            set_color green
        end
        echo -n $git_branch
        if test $git_dirty_count -gt 0
            echo -n " "✘
        else
            echo -n " "✓
        end
    end
    set_color normal
    printf "\n\$ "
end

# mvim alias
function m
	mvim $argv
end

# Git flow aliases
function feature
	g feature start $argv
end

function release
	g release start
end

function hotfix
	g hotfix start
end

# Finish a Git Flow branch with the Golem wrapper
function finish
	switch (git-curr-branch-type)
	case "feature"
		g feature finish
	case "hotfix"
		g hotfix finish
	case "release"
		g release finish
	case "*"
		echo "You can't finish this type of branch."
	end
end

# Reload fish profile
alias reload='source ~/.config/fish/config.fish'

# Restart apache
alias restart='sudo apachectl restart'

# MySQL on the cli
alias mysql='/usr/local/mysql/bin/mysql'

# Garp and Golem aliases
alias garp='php garp/scripts/garp\.php'
alias golem='php ~/Sites/golem/scripts/golem\.php'
alias g='golem'
alias gl='git pull'
alias gp='git push'
alias gs='git status'
alias gpg='sh garp/scripts/push_changes.sh'
alias gpullcore='sh core/scripts/pull_changes.sh'
alias gpushcore='sh core/scripts/push_changes.sh'

# Composer
alias composer="/usr/local/bin/composer.phar"

# cd stuff
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"
alias .....="cd ../../../../"
