function mb --description "Worktree workflow helper (worktrunk + tmux + claude)"
    switch $argv[1]
        case start
            # mb start my-feature            → new worktree + branch, cd, rename window, launch claude
            # mb start my-feature -- "prompt" → same, but starts claude with an initial prompt
            wt switch --create -x claude $argv[2..-1]
        case complete
            # Tear down the current worktree, then kill the tmux window.
            # `wt remove` refuses a dirty worktree (and deletes the branch
            # only if it's already merged), so the window is killed only
            # when teardown actually succeeded. Extra flags pass through:
            #   mb complete --force   remove even if dirty
            #   mb complete --reap    also kill leftover dev servers
            wt remove $argv[2..-1]; or return 1
            test -n "$TMUX"; and tmux kill-window
        case '*'
            echo "usage: mb start <name> [-- <claude prompt>]"
            echo "       mb complete [--force] [--reap]"
            return 1
    end
end
