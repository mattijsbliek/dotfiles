# Platform-specific configuration

switch (uname)
    case Darwin
        # Homebrew (Apple Silicon)
        fish_add_path /opt/homebrew/bin /opt/homebrew/sbin

        # 1Password SSH agent (macOS)
        set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

    case Linux
        # 1Password SSH agent (Linux)
        if test -S "$HOME/.1password/agent.sock"
            set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
        end
end
