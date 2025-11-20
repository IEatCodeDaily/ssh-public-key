# IEatCodeDaily zshrc: https://raw.githubusercontent.com/IEatCodeDaily/infra-scripts/main/config/.zshrc

# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="wedisagree"

# Enable command correction
ENABLE_CORRECTION="false"

# Display red dots while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Plugins
plugins=(
    git
    docker
    sudo
    history
    copypath
    dirhistory
    jsontools
    colored-man-pages
    command-not-found
)

source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias vi='vim'
alias fm='ranger'  # ranger file manager

# Check if bat is installed as batcat (Debian) and create alias
if command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
fi

# Load fzf if available
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load zsh-autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load zsh-syntax-highlighting (must be at the end)
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Set up tab completion menu behavior
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# Enable directory navigation with just the directory name
setopt autocd

# Key bindings - simple version less likely to cause encoding issues
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Start SSH agent if not already running
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
fi

# Add all keys in ~/.ssh/keys directory
if [ -d "$HOME/.ssh/keys" ]; then
  for key in "$HOME"/.ssh/keys/*; do
    # Only add private keys that don't have .pub extension
    if [ -f "$key" ] && [[ "$key" != *.pub ]]; then
      ssh-add "$key" 2>/dev/null
    fi
  done
fi
