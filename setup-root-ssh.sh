#!/bin/bash

# Create .ssh directory if it doesn't exist
mkdir -p /root/.ssh

# Download and add the key using wget
wget -qO- https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/refs/heads/main/ec-ssh-rpw.pub >> /root/.ssh/authorized_keys

# Set correct permissions
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Verify the key was added
echo "Key added. Current authorized_keys content:"
cat /root/.ssh/authorized_keys
