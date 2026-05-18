# https://dev.to/joaovitor/bat-instead-of-cat-a86
alias cat='bat'
alias l='eza'
alias la='eza -al --group-directories-first'
alias ll='eza -l --group-directories-first'
alias ls="eza --group-directories-first"

# zsh history
HISTFILE=/workspaces/commandhistory/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
# write to history file immediately, but don't share between active sessions
# https://unix.stackexchange.com/questions/389881/history-isnt-preserved-in-zsh#comment858751_470707
setopt INC_APPEND_HISTORY

# zsh history substring search
bindkey ';2A' history-substring-search-up    # Shift+Up
bindkey ';2B' history-substring-search-down  # Shift+Down
