#!/bin/bash

################################################################################
# Complete Terminal Setup Script
#
# This script installs and configures a terminal environment with:
#   - zsh with Oh My Zsh
#   - tmux terminal multiplexer
#   - ranger file manager
#   - fzf fuzzy finder
#   - Other useful tools (ripgrep, bat, htop, fastfetch, ncdu)
#
# Usage:
#   curl -s https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup-shell.sh | sudo bash
#   wget -O- https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup-shell.sh | sudo bash
################################################################################

# Check if running with bash
if [ -z "$BASH_VERSION" ]; then
    echo "ERROR: This script requires bash, but it's being run with sh or another shell."
    echo "Please use one of the following commands instead:"
    echo ""
    echo "  curl -s https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup-shell.sh | sudo bash"
    echo ""
    echo "  wget -O- https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup-shell.sh | sudo bash"
    echo ""
    echo "Note: Use 'bash' at the end, NOT 'sh'"
    exit 1
fi

set -o pipefail  # Safer pipe handling

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${GREEN}>> $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_step() {
    echo -e "${BLUE}>> $1${NC}"
}

# Check if running as root and exit if not
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root or with sudo privileges."
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

print_step "Starting terminal setup for user: $ACTUAL_USER"
print_step "Home directory: $USER_HOME"
echo ""

# Fix GPG key issues and update package lists
print_info "Updating package lists..."
if ! apt-get update; then
    print_warning "Package list update had issues, attempting to fix..."
    apt-get install -y gnupg
    apt-get install -y debian-archive-keyring
    apt-key update
    apt-get update || print_warning "Package list update still has issues, continuing anyway..."
fi

# Install basic tools
print_info "Installing basic tools..."
apt-get install -y git curl wget build-essential unzip

# Install ranger file manager and dependencies for preview capabilities
print_info "Installing ranger file manager and dependencies..."
apt-get install -y ranger highlight caca-utils atool w3m poppler-utils mediainfo

# Install tmux
print_info "Installing tmux..."
apt-get install -y tmux

# Install zsh
print_info "Installing zsh..."
apt-get install -y zsh

# Install fzf for fuzzy searching
print_info "Installing fzf..."
apt-get install -y fzf || print_warning "fzf installation failed, continuing..."

# Install other useful tools
print_info "Installing additional tools..."
apt-get install -y ripgrep ncdu htop || {
    print_warning "Some tools might not be available in the standard repositories."
    print_warning "Installing available tools and continuing..."
    apt-get install -y ripgrep || true
    apt-get install -y ncdu || true
    apt-get install -y htop || true
}

# Install fastfetch from GitHub releases (much faster than neofetch)
print_info "Installing fastfetch..."
FASTFETCH_VERSION=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
FASTFETCH_URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.deb"
if curl -fsSL "$FASTFETCH_URL" -o /tmp/fastfetch.deb; then
    dpkg -i /tmp/fastfetch.deb || apt-get install -y -f
    rm -f /tmp/fastfetch.deb
    print_info "fastfetch ${FASTFETCH_VERSION} installed successfully"
else
    print_warning "Failed to download fastfetch, falling back to neofetch..."
    apt-get install -y neofetch || print_warning "neofetch installation also failed"
fi

# Install bat (sometimes packaged as batcat in Debian)
apt-get install -y bat || apt-get install -y batcat || true

# Create zsh plugin directory
print_info "Creating zsh plugin directory..."
mkdir -p ${USER_HOME}/.zsh
chown -R $ACTUAL_USER:$ACTUAL_USER ${USER_HOME}/.zsh

# Install zsh-autosuggestions for command suggestions
print_info "Installing zsh-autosuggestions..."
if [ -d "${USER_HOME}/.zsh/zsh-autosuggestions" ]; then
    print_info "zsh-autosuggestions already installed, updating..."
    cd ${USER_HOME}/.zsh/zsh-autosuggestions && git pull || print_warning "Failed to update zsh-autosuggestions"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions ${USER_HOME}/.zsh/zsh-autosuggestions
fi
chown -R $ACTUAL_USER:$ACTUAL_USER ${USER_HOME}/.zsh/zsh-autosuggestions

# Install zsh-syntax-highlighting for syntax highlighting
print_info "Installing zsh-syntax-highlighting..."
if [ -d "${USER_HOME}/.zsh/zsh-syntax-highlighting" ]; then
    print_info "zsh-syntax-highlighting already installed, updating..."
    cd ${USER_HOME}/.zsh/zsh-syntax-highlighting && git pull || print_warning "Failed to update zsh-syntax-highlighting"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${USER_HOME}/.zsh/zsh-syntax-highlighting
fi
chown -R $ACTUAL_USER:$ACTUAL_USER ${USER_HOME}/.zsh/zsh-syntax-highlighting

# Install Oh My Zsh for zsh configuration
print_info "Installing Oh My Zsh..."
if [ -d "${USER_HOME}/.oh-my-zsh" ]; then
    print_info "Oh My Zsh already installed, updating..."
    cd ${USER_HOME}/.oh-my-zsh && git pull || print_warning "Failed to update Oh My Zsh"
else
    # Download and run the installer non-interactively
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi
chown -R $ACTUAL_USER:$ACTUAL_USER ${USER_HOME}/.oh-my-zsh

# Download configuration files from GitHub repository
print_info "Downloading configuration files from GitHub..."

# Create or backup existing config files
if [ -f "${USER_HOME}/.zshrc" ]; then
    print_info "Backing up existing .zshrc..."
    cp "${USER_HOME}/.zshrc" "${USER_HOME}/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

if [ -f "${USER_HOME}/.tmux.conf" ]; then
    print_info "Backing up existing .tmux.conf..."
    cp "${USER_HOME}/.tmux.conf" "${USER_HOME}/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
fi

# Download config files from GitHub with error handling
if ! curl -fsSL https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/config/.zshrc -o "${USER_HOME}/.zshrc"; then
    print_warning "Failed to download .zshrc from GitHub, using local default..."
    # Use local default .zshrc from config folder if available
    if [ -f "/mnt/e/Projects/ssh-public-key/config/.zshrc" ]; then
        cp /mnt/e/Projects/ssh-public-key/config/.zshrc "${USER_HOME}/.zshrc"
    else
        print_warning "Local .zshrc not found, using embedded default..."
        # Embedded fallback configuration
        cat > "${USER_HOME}/.zshrc" << 'EOF'
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="xiong-chiamiov-plus"

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
alias fm='ranger'

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

# Enable directory navigation with just by directory name
setopt autocd

# Key bindings
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[Z' reverse-menu-complete

# Run fastfetch on startup (much faster than neofetch)
if command -v fastfetch >/dev/null 2>&1; then
  fastfetch
else
  neofetch
fi
EOF
    fi
fi

if ! curl -fsSL https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/config/.tmux.conf -o "${USER_HOME}/.tmux.conf"; then
    print_warning "Failed to download .tmux.conf from GitHub, using local default..."
    if [ -f "/mnt/e/Projects/ssh-public-key/config/.tmux.conf" ]; then
        cp /mnt/e/Projects/ssh-public-key/config/.tmux.conf "${USER_HOME}/.tmux.conf"
    else
        print_warning "Local .tmux.conf not found, skipping tmux configuration..."
    fi
fi

# Set correct ownership for config files
chown $ACTUAL_USER:$ACTUAL_USER ${USER_HOME}/.zshrc
chown $ACTUAL_USER:$ACTUAL_USER ${USER_HOME}/.tmux.conf

# Create ranger configuration directory
print_info "Setting up ranger file manager..."
mkdir -p "${USER_HOME}/.config/ranger"
chown -R $ACTUAL_USER:$ACTUAL_USER ${USER_HOME}/.config/ranger

# Generate default ranger configuration (if it doesn't exist)
if [ ! -f "${USER_HOME}/.config/ranger/rc.conf" ]; then
    su - $ACTUAL_USER -c "ranger --copy-config=all" || print_warning "Failed to generate ranger config"
fi

# Add fm alias for ranger to .zshrc if it doesn't exist
if ! grep -q "alias fm='ranger'" "${USER_HOME}/.zshrc"; then
    print_info "Adding ranger alias to .zshrc..."
    echo "" >> "${USER_HOME}/.zshrc"
    echo "# Ranger file manager alias" >> "${USER_HOME}/.zshrc"
    echo "alias fm='ranger'" >> "${USER_HOME}/.zshrc"
fi

# Add fastfetch to the end of .zshrc to run it on every terminal start
if ! grep -q "# Run fastfetch on startup" "${USER_HOME}/.zshrc"; then
    print_info "Adding fastfetch to startup in .zshrc..."
    echo "" >> "${USER_HOME}/.zshrc"
    echo "# Run fastfetch on startup (much faster than neofetch)" >> "${USER_HOME}/.zshrc"
    echo "if command -v fastfetch >/dev/null 2>&1; then" >> "${USER_HOME}/.zshrc"
    echo "  fastfetch" >> "${USER_HOME}/.zshrc"
    echo "fi" >> "${USER_HOME}/.zshrc"
fi

# Set zsh as default shell for user
print_info "Setting zsh as default shell..."
chsh -s $(which zsh) $ACTUAL_USER

# Display summary
echo ""
print_info "========================================="
print_info "Installation complete!"
print_info "========================================="
echo ""
print_info "Installed packages:"
print_info "  - zsh (with Oh My Zsh)"
print_info "  - tmux (terminal multiplexer)"
print_info "  - ranger (file manager)"
print_info "  - fzf (fuzzy finder)"
print_info "  - ripgrep (fast grep)"
print_info "  - bat (better cat)"
print_info "  - htop (process viewer)"
print_info "  - fastfetch (system info, 276x faster than neofetch)"
print_info "  - ncdu (disk usage analyzer)"
echo ""
print_info "Configuration files:"
print_info "  - ~/.zshrc (zsh configuration)"
print_info "  - ~/.tmux.conf (tmux configuration)"
print_info "  - ~/.config/ranger/ (ranger configuration)"
echo ""
print_info "Starting zsh with fastfetch now..."
echo ""

# Create a temporary script to launch zsh with fastfetch for the current session
TMP_SCRIPT=$(mktemp)
cat > $TMP_SCRIPT << EOL
#!/bin/bash
if command -v fastfetch >/dev/null 2>&1; then
  fastfetch
else
  neofetch
fi
exec zsh
EOL

chmod +x $TMP_SCRIPT

# Launch zsh for the user
print_step "Switching to user $ACTUAL_USER and launching zsh..."
su - $ACTUAL_USER -c "$TMP_SCRIPT"

# Clean up
rm -f $TMP_SCRIPT
