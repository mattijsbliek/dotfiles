function m --description "Worktree workflow helper (worktrunk + tmux + claude) and misc utilities"
    switch $argv[1]
        case start
            # m start my-feature            → new worktree + branch, cd, rename window, launch claude
            # m start my-feature -- "prompt" → same, but starts claude with an initial prompt
            wt switch --create -x claude $argv[2..-1]
        case cleanup
            # Tear down the current worktree, then kill the tmux window (or
            # herdr tab, whichever we're running in).
            # `wt remove` refuses a dirty worktree (and deletes the branch
            # only if it's already merged), so the window is killed only
            # when teardown actually succeeded. Extra flags pass through:
            #   m cleanup --force   remove even if dirty
            #   m cleanup --reap    also kill leftover dev servers
            wt remove $argv[2..-1]; or return 1
            if test -n "$TMUX"
                tmux kill-window
            else if test -n "$HERDR_ENV"
                # herdr refuses to close a tab if it's the last one in its
                # workspace (would leave an empty workspace behind), so fall
                # back to closing the whole workspace in that case.
                herdr tab close "$HERDR_TAB_ID" 2>/dev/null; or herdr workspace close "$HERDR_WORKSPACE_ID"
            end
        case prune
            # Bulk-remove worktrees/branches already merged into the default
            # branch (stale ones left behind after a manual merge, forgotten
            # `m cleanup`, etc). Skips the main worktree, locked worktrees,
            # and anything younger than 1 day. Doesn't touch tmux windows for
            # the removed worktrees — only `m cleanup` does that.
            #   m prune --dry-run   preview without removing anything
            wt step prune $argv[2..-1]
        case paste-image
            # Paste the clipboard image, scp it to hl-claude:/tmp, print the remote path.
            set -l tmp (mktemp /tmp/paste-image-XXXXXX)
            set -l local_path $tmp.png
            mv $tmp $local_path

            if not pngpaste $local_path
                rm -f $local_path
                echo "m paste-image: no image on clipboard" >&2
                return 1
            end

            set -l remote_path /tmp/(basename $local_path)
            if not scp -q $local_path hl-claude:$remote_path
                rm -f $local_path
                return 1
            end

            rm -f $local_path
            echo -n $remote_path | pbcopy
            echo $remote_path
        case '*'
            echo "usage: m start <name> [-- <claude prompt>]"
            echo "       m cleanup [--force] [--reap]"
            echo "       m prune [--dry-run] [--min-age <duration>]"
            echo "       m paste-image"
            return 1
    end
end
