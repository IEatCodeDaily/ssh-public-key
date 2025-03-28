#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Script to create a new user 'rpw' with SSH public key access
# Run this script with sudo or as root

# Check if script is being run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# Create the new user
echo "Creating new user 'rpw'..."
useradd -m -s /bin/bash rpw

# Create .ssh directory for the new user
echo "Setting up SSH directory..."
mkdir -p /home/rpw/.ssh
chmod 700 /home/rpw/.ssh

# Download the public key from GitHub
echo "Downloading SSH public key..."
curl -s https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/refs/heads/main/ssh-rpw.pub > /home/rpw/.ssh/authorized_keys

# Set proper permissions for authorized_keys file
chmod 600 /home/rpw/.ssh/authorized_keys

# Set proper ownership
chown -R rpw:rpw /home/rpw/.ssh

# Verify that SSH access is enabled in sshd_config
if grep -q "^#PubkeyAuthentication yes" /etc/ssh/sshd_config; then
    echo "Enabling public key authentication in SSH config..."
    sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
fi

# Ensure password authentication is disabled (optional security measure)
if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
    echo "Disabling password authentication in SSH config (for security)..."
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
fi

echo "User 'rpw' has been created successfully with SSH public key access."
echo "The user can now log in using: ssh rpw@your_server_ip"
