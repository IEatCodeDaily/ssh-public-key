#!/bin/bash

# Exit on any error
set -e

# Function to print messages
print_message() {
    echo "==> $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Install SSH server if not already installed
print_message "Installing OpenSSH Server..."
apt-get update
apt-get install -y openssh-server

# Backup original SSH config
print_message "Backing up original SSH config..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Configure SSH with minimal restrictions
print_message "Configuring SSH..."
cat > /etc/ssh/sshd_config <<EOL
# Basic SSH Configuration
Port 22
Protocol 2

# Authentication
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no

# Other Settings
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOL

# Start and enable SSH service
print_message "Starting and enabling SSH service..."
systemctl restart ssh
systemctl enable ssh

# Final status check
print_message "Checking SSH service status..."
systemctl status ssh

print_message "SSH setup completed successfully!"
print_message "SSH is running on default port 22"
print_message "You can now connect using password or SSH keys"
