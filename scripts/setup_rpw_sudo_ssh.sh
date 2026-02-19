#!/bin/bash

################################################################################
# Script to create a new user 'rpw' with SSH public key access and sudo privileges
# Run this script with sudo or as root
#
# This script will:
# 1. Create user 'rpw' if it doesn't exist
# 2. Setup SSH directory with proper permissions
# 3. Install SSH public key for authentication
# 4. Configure SSH settings for public key authentication
# 5. Grant sudo privileges (optional NOPASSWD)
#
# Usage:
#   curl -s https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup_rpw_sudo_ssh.sh | sudo bash
#   wget -O- https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup_rpw_sudo_ssh.sh | sudo bash
#
# For passwordless sudo (NOPASSWD), set the environment variable:
#   export SUDO_NOPASSWD=true
# or run with:
#   curl -s ... | sudo SUDO_NOPASSWD=true bash
################################################################################

set -e  # Exit immediately if a command exits with a non-zero status

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

print_question() {
    echo -e "${BLUE}>> $1${NC}"
}

# Check if script is being run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

# Check if user already exists
if id "rpw" &>/dev/null; then
    print_warning "User 'rpw' already exists"
    
    # Check if running in interactive mode (stdin is a terminal)
    if [ -t 0 ]; then
        # Interactive mode - ask for confirmation
        read -p "Do you want to update SSH keys and sudo privileges for existing user? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting script without making changes"
            exit 0
        fi
    else
        # Non-interactive mode (piped from curl/wget) - automatically update
        print_info "Running in non-interactive mode - automatically updating SSH keys and sudo privileges"
    fi
    
    print_info "Updating SSH keys and sudo privileges for existing user 'rpw'..."
    USER_EXISTS=true
else
    print_info "Creating new user 'rpw'..."
    USER_EXISTS=false
fi

# Create the new user if it doesn't exist
if [ "$USER_EXISTS" = false ]; then
    if ! useradd -m -s /bin/bash rpw; then
        print_error "Failed to create user 'rpw'"
        exit 1
    fi
    print_info "User 'rpw' created successfully"
fi

# Create .ssh directory for the user
print_info "Setting up SSH directory..."
mkdir -p /home/rpw/.ssh
chmod 700 /home/rpw/.ssh
chown rpw:rpw /home/rpw/.ssh

# Download the public key from GitHub
print_info "Downloading SSH public key..."
if ! curl -fsSL https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/keys/ssh-rpw.pub -o /home/rpw/.ssh/authorized_keys; then
    print_error "Failed to download SSH public key"
    print_error "Please check your internet connection or the key URL"
    exit 1
fi

# Verify the key was downloaded and is not empty
if [ ! -s /home/rpw/.ssh/authorized_keys ]; then
    print_error "Downloaded SSH key is empty or invalid"
    exit 1
fi

# Set proper permissions for authorized_keys file
chmod 600 /home/rpw/.ssh/authorized_keys
chown rpw:rpw /home/rpw/.ssh/authorized_keys

print_info "SSH public key installed successfully"

# Grant sudo privileges to user
print_info "Configuring sudo privileges..."

# Check if we should use NOPASSWD sudo
USE_NOPASSWD="${SUDO_NOPASSWD:-false}"
if [ "$USE_NOPASSWD" = false ]; then
    # Only prompt if running in interactive mode
    if [ -t 0 ]; then
        print_question "Do you want passwordless sudo access (NOPASSWD)? (y/n) [n]: "
        read -r -n 1 -t 30 response 2>/dev/null || response="n"
        echo
        if [[ $response =~ ^[Yy]$ ]]; then
            USE_NOPASSWD=true
        fi
    else
        # Non-interactive mode - default to false
        print_info "Non-interactive mode: Using default sudo configuration (password required)"
    fi
fi

# Check if we're on a Debian/Ubuntu system with sudo group
SUDO_CONFIGURED=false
if getent group sudo > /dev/null; then
    # Add user to sudo group
    usermod -aG sudo rpw
    print_info "Added 'rpw' to sudo group"
    SUDO_CONFIGURED=true
elif getent group wheel > /dev/null; then
    # Add user to wheel group on CentOS/RHEL/Fedora
    usermod -aG wheel rpw
    print_info "Added 'rpw' to wheel group"
    SUDO_CONFIGURED=true
else
    # Directly add to sudoers file if groups are not available
    if [ "$USE_NOPASSWD" = true ]; then
        echo "rpw ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/rpw
    else
        echo "rpw ALL=(ALL) ALL" > /etc/sudoers.d/rpw
    fi
    chmod 440 /etc/sudoers.d/rpw
    print_info "Added 'rpw' to sudoers file"
    SUDO_CONFIGURED=true
fi

# Configure NOPASSWD if requested and user was added to sudo/wheel group
if [ "$USE_NOPASSWD" = true ] && [ "$SUDO_CONFIGURED" = true ]; then
    # Check if sudoers.d directory exists
    if [ -d /etc/sudoers.d ]; then
        # Create sudoers entry for NOPASSWD
        echo "rpw ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/rpw
        chmod 440 /etc/sudoers.d/rpw
        print_info "Configured passwordless sudo (NOPASSWD)"
    else
        print_warning "Cannot configure NOPASSWD: /etc/sudoers.d doesn't exist"
        print_warning "User will need to enter password for sudo commands"
    fi
fi

# Verify that SSH access is enabled in sshd_config
SSHD_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONFIG" ]; then
    # Enable public key authentication if commented out
    if grep -q "^#PubkeyAuthentication yes" "$SSHD_CONFIG"; then
        print_info "Enabling public key authentication in SSH config..."
        sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSHD_CONFIG"
        SSH_RESTART_NEEDED=true
    fi

    # Ensure password authentication is disabled (security measure)
    if grep -q "^PasswordAuthentication yes" "$SSHD_CONFIG"; then
        print_info "Disabling password authentication in SSH config (for security)..."
        sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' "$SSHD_CONFIG"
        SSH_RESTART_NEEDED=true
    fi

    # Restart SSH service if config was changed
    if [ "$SSH_RESTART_NEEDED" = true ]; then
        if systemctl is-active --quiet sshd || systemctl is-active --quiet ssh; then
            print_info "Restarting SSH service..."
            systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        else
            print_warning "SSH service doesn't appear to be running. Please start it manually."
        fi
    fi
else
    print_warning "SSH config file not found at $SSHD_CONFIG. Skipping SSH configuration."
fi

# Display summary
echo ""
print_info "========================================="
print_info "Setup completed successfully!"
print_info "========================================="
echo ""
print_info "User: rpw"
print_info "SSH Directory: /home/rpw/.ssh"
print_info "Public Key: ssh-rpw.pub (ed25519)"
print_info "Sudo Access: Enabled"
if [ "$USE_NOPASSWD" = true ]; then
    print_info "Passwordless Sudo: Enabled (NOPASSWD)"
else
    print_info "Passwordless Sudo: Disabled (password required)"
fi
echo ""
print_info "The user can now log in using: ssh rpw@your_server_ip"
if [ "$USE_NOPASSWD" = true ]; then
    print_info "The user can execute commands with sudo without password."
else
    print_info "The user can execute commands with sudo (password required)."
fi
echo ""
