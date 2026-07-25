function m --description "Worktree workflow helper (worktrunk + tmux + claude)"
    switch $argv[1]
        case start
            # m start my-feature            → new worktree + branch, cd, rename window, launch claude
            # m start my-feature -- "prompt" → same, but starts claude with an initial prompt
            wt switch --create -x claude $argv[2..-1]
        case cleanup
            # Tear down the current worktree, then kill the tmux window.
            # `wt remove` refuses a dirty worktree (and deletes the branch
            # only if it's already merged), so the window is killed only
            # when teardown actually succeeded. Extra flags pass through:
            #   m cleanup --force   remove even if dirty
            #   m cleanup --reap    also kill leftover dev servers
            wt remove $argv[2..-1]; or return 1
            test -n "$TMUX"; and tmux kill-window
        case prune
            # Bulk-remove worktrees/branches already merged into the default
            # branch (stale ones left behind after a manual merge, forgotten
            # `m cleanup`, etc). Skips the main worktree, locked worktrees,
            # and anything younger than 1 day. Doesn't touch tmux windows for
            # the removed worktrees — only `m cleanup` does that.
            #   m prune --dry-run   preview without removing anything
            wt step prune $argv[2..-1]
        case '*'
            echo "usage: m start <name> [-- <claude prompt>]"
            echo "       m cleanup [--force] [--reap]"
            echo "       m prune [--dry-run] [--min-age <duration>]"
            return 1
    end
end
