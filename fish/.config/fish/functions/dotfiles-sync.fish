function dotfiles-sync -d "Pull and restow dotfiles"
    set -l dotfiles_dir ~/dotfiles

    if not test -d $dotfiles_dir
        # Fall back to ~/Sites/dotfiles if ~/dotfiles doesn't exist
        set dotfiles_dir ~/Sites/dotfiles
    end

    if not test -d $dotfiles_dir
        echo "Error: dotfiles directory not found"
        return 1
    end

    git -C $dotfiles_dir pull --rebase
    cd $dotfiles_dir
    for pkg in bash fish nvim git claude starship ghostty
        stow -R $pkg
    end
    cd -
    echo "Dotfiles synced."
end
