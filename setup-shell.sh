#!/bin/bash

# Complete Terminal Setup Script
# This script installs and configures a terminal environment with tmux, zsh,
# ranger file manager, and other useful shell tools.

# Allow some commands to fail without exiting the script
set -o pipefail  # Safer pipe handling

# Print colored output
print_message() {
    echo -e "\e[1;34m>> $1\e[0m"
}

# Check if running as root and exit if not
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

# Get the username of the user who called sudo
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
    ACTUAL_USER=$SUDO_USER
else
    USER_HOME=$HOME
    ACTUAL_USER=$(whoami)
fi

# Fix GPG key issues and update package lists
print_message "Fixing GPG keys and updating package lists..."
apt-get install -y gnupg
apt-get install -y debian-archive-keyring
apt-key update
apt-get update || {
    print_message "Attempting to fix repository signature issues..."
    apt-get install -y --allow-unauthenticated debian-archive-keyring
    apt-key update
    # Alternative approach to fix Debian security repository
    gpg --keyserver keyserver.ubuntu.com --recv-keys 54404762BBB6E853
    gpg --export 54404762BBB6E853 | apt-key add -
    # Update package lists again
    apt-get update --allow-unauthenticated || print_message "Warning: Package list update had issues, but continuing anyway..."
}

# Install basic tools
print_message "Installing basic tools..."
apt-get install -y git curl wget build-essential unzip

# Install ranger file manager and dependencies for preview capabilities
print_message "Installing ranger file manager and dependencies..."
apt-get install -y ranger highlight caca-utils atool w3m poppler-utils mediainfo

# Install tmux
print_message "Installing tmux..."
apt-get install -y tmux

# Install zsh
print_message "Installing zsh..."
apt-get install -y zsh

# Install fzf for fuzzy searching
print_message "Installing fzf..."
apt-get install -y fzf || print_message "Warning: fzf installation failed, continuing..."

# Install other useful tools
print_message "Installing additional tools..."
apt-get install -y ripgrep ncdu htop neofetch || {
    print_message "Some tools might not be available in the standard repositories."
    print_message "Installing available tools and continuing..."
    apt-get install -y ripgrep || true
    apt-get install -y ncdu || true
    apt-get install -y htop || true
    apt-get install -y neofetch || true
}

# Install bat (sometimes packaged as batcat in Debian)
apt-get install -y bat || apt-get install -y batcat || true

# Create zsh plugin directory
print_message "Creating zsh plugin directory..."
mkdir -p ${USER_HOME}/.zsh

# Install zsh-autosuggestions for command suggestions
print_message "Installing zsh-autosuggestions..."
if [ -d "${USER_HOME}/.zsh/zsh-autosuggestions" ]; then
    print_message "zsh-autosuggestions already installed, updating..."
    cd ${USER_HOME}/.zsh/zsh-autosuggestions && git pull
else
    git clone https://github.com/zsh-users/zsh-autosuggestions ${USER_HOME}/.zsh/zsh-autosuggestions
fi

# Install zsh-syntax-highlighting for syntax highlighting
print_message "Installing zsh-syntax-highlighting..."
if [ -d "${USER_HOME}/.zsh/zsh-syntax-highlighting" ]; then
    print_message "zsh-syntax-highlighting already installed, updating..."
    cd ${USER_HOME}/.zsh/zsh-syntax-highlighting && git pull
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${USER_HOME}/.zsh/zsh-syntax-highlighting
fi

# Install Oh My Zsh for zsh configuration
print_message "Installing Oh My Zsh..."
if [ -d "${USER_HOME}/.oh-my-zsh" ]; then
    print_message "Oh My Zsh already installed, updating..."
    if [ -n "$SUDO_USER" ]; then
        su - $SUDO_USER -c "cd ${USER_HOME}/.oh-my-zsh && git pull"
    else
        cd ${USER_HOME}/.oh-my-zsh && git pull
    fi
else
    if [ -n "$SUDO_USER" ]; then
        su - $SUDO_USER -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
    fi
fi

# Download configuration files from GitHub repository
print_message "Downloading configuration files from GitHub..."

# Create or backup existing config files
if [ -f "${USER_HOME}/.zshrc" ]; then
    print_message "Backing up existing .zshrc..."
    cp "${USER_HOME}/.zshrc" "${USER_HOME}/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

if [ -f "${USER_HOME}/.tmux.conf" ]; then
    print_message "Backing up existing .tmux.conf..."
    cp "${USER_HOME}/.tmux.conf" "${USER_HOME}/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
fi

# Download config files from GitHub
curl -fsSL https://raw.githubusercontent.com/IEatCodeDaily/infra-scripts/main/config/.zshrc -o "${USER_HOME}/.zshrc"
curl -fsSL https://raw.githubusercontent.com/IEatCodeDaily/infra-scripts/main/config/.tmux.conf -o "${USER_HOME}/.tmux.conf"

# Create ranger configuration directory
mkdir -p "${USER_HOME}/.config/ranger"

# Generate default ranger configuration (if it doesn't exist)
if [ -n "$SUDO_USER" ]; then
    su - $SUDO_USER -c "ranger --copy-config=all"
else
    ranger --copy-config=all
fi

# Add fm alias for ranger to .zshrc if it doesn't exist
if ! grep -q "alias fm='ranger'" "${USER_HOME}/.zshrc"; then
    print_message "Adding ranger alias to .zshrc..."
    echo "# Ranger file manager alias" >> "${USER_HOME}/.zshrc"
    echo "alias fm='ranger'" >> "${USER_HOME}/.zshrc"
fi

# Add neofetch to the end of .zshrc to run it on every terminal start
if ! grep -q "# Run neofetch on startup" "${USER_HOME}/.zshrc"; then
    print_message "Adding neofetch to startup in .zshrc..."
    echo "" >> "${USER_HOME}/.zshrc"
    echo "# Run neofetch on startup" >> "${USER_HOME}/.zshrc"
    echo "neofetch" >> "${USER_HOME}/.zshrc"
fi

# If any download fails, use local default config
if [ ! -f "${USER_HOME}/.zshrc" ]; then
    print_message "Failed to download .zshrc, using local default..."
    cat > "${USER_HOME}/.zshrc" << 'EOL'
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="xiong-chiamiov-plus"

# Enable command correction
ENABLE_CORRECTION="true"

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

# Key bindings
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[Z' reverse-menu-complete

# Run neofetch on startup
neofetch
EOL
fi

# Set correct ownership if script was run with sudo
if [ -n "$SUDO_USER" ]; then
    print_message "Setting correct ownership of files..."
    chown -R $SUDO_USER:$SUDO_USER ${USER_HOME}/.oh-my-zsh
    chown -R $SUDO_USER:$SUDO_USER ${USER_HOME}/.zsh
    chown -R $SUDO_USER:$SUDO_USER ${USER_HOME}/.config/ranger
    chown $SUDO_USER:$SUDO_USER ${USER_HOME}/.zshrc
    chown $SUDO_USER:$SUDO_USER ${USER_HOME}/.tmux.conf
fi

# Set zsh as default shell for the user
print_message "Setting zsh as default shell..."
if [ -n "$SUDO_USER" ]; then
    chsh -s $(which zsh) $SUDO_USER
else
    chsh -s $(which zsh)
fi

print_message "Installation complete!"
print_message "Starting zsh with neofetch now..."

# Create a temporary script to launch zsh with neofetch for the current session
TMP_SCRIPT=$(mktemp)
cat > $TMP_SCRIPT << EOL
#!/bin/bash
neofetch
exec zsh
EOL

chmod +x $TMP_SCRIPT

# Launch zsh for the user
if [ -n "$SUDO_USER" ]; then
    print_message "Switching to user $SUDO_USER and launching zsh..."
    su - $SUDO_USER -c "$TMP_SCRIPT"
else
    # Run directly
    bash $TMP_SCRIPT
fi

# Clean up
rm -f $TMP_SCRIPT
