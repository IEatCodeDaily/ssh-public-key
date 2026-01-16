# SSH Public Key Repository

This repository contains SSH public keys and setup scripts for configuring remote servers with SSH access.

## Quick Setup

### With Sudo Access (Passwordless Option)

Creates user `rpw` with SSH access and sudo privileges. Optionally enables passwordless sudo.

```bash
curl -s https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup_rpw_sudo_ssh.sh | sudo sh
```

or

```bash
wget -O- https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup_rpw_sudo_ssh.sh | sudo sh
```

To enable passwordless sudo (NOPASSWD), set the environment variable:

```bash
curl -s https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup_rpw_sudo_ssh.sh | sudo SUDO_NOPASSWD=true sh
```

### Without Sudo Access

Creates user `rpw` with SSH access only (no sudo privileges).

```bash
curl -s https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup_rpw_ssh.sh | sudo sh
```

or

```bash
wget -O- https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup_rpw_ssh.sh | sudo sh
```

## Scripts

### `scripts/setup_rpw_ssh.sh`

Creates a new user `rpw` with SSH public key access. This user does **not** have sudo privileges.

**Features:**
- Creates user if it doesn't exist
- Installs SSH public key for authentication
- Configures SSH settings for security
- Updates existing user's SSH keys if already present

**Requirements:**
- Must run with `sudo` or as root
- Internet connection to download the public key
- SSH service installed on the target system

### `scripts/setup_rpw_sudo_ssh.sh`

Creates a new user `rpw` with SSH public key access and sudo privileges.

**Features:**
- Creates user if it doesn't exist
- Installs SSH public key for authentication
- Grants sudo access (optionally passwordless)
- Configures SSH settings for security
- Updates existing user's SSH keys and sudo privileges if already present

**Requirements:**
- Must run with `sudo` or as root
- Internet connection to download the public key
- SSH service installed on the target system

### `scripts/setup-shell.sh`

Sets up a complete terminal environment with:

- **Shell:** zsh with Oh My Zsh
- **Terminal Multiplexer:** tmux
- **File Manager:** ranger with preview capabilities
- **Fuzzy Finder:** fzf
- **Other Tools:** ripgrep, bat, htop, neofetch, ncdu

**Features:**
- Installs all necessary packages
- Configures zsh with plugins and themes
- Sets up tmux with useful keybindings
- Configures ranger for better file navigation
- Automatically downloads configuration files from this repository

**Usage:**
```bash
curl -s https://raw.githubusercontent.com/IEatCodeDaily/ssh-public-key/main/scripts/setup-shell.sh | sudo sh
```

## Repository Structure

```
.
├── README.md                 # This file
├── config/                  # Configuration files
│   ├── .zshrc              # zsh configuration
│   └── .tmux.conf          # tmux configuration
├── keys/                    # SSH public keys
│   ├── ssh-rpw.pub         # ed25519 key (recommended)
│   └── ec-ssh-rpw.pub     # RSA key (legacy)
└── scripts/                 # Setup scripts
    ├── setup_rpw_ssh.sh            # User setup without sudo
    ├── setup_rpw_sudo_ssh.sh       # User setup with sudo
    └── setup-shell.sh             # Complete terminal setup
```

## SSH Keys

### `keys/ssh-rpw.pub` (Recommended)
- **Type:** ed25519
- **Algorithm:** EdDSA
- **Size:** 256-bit
- **Advantages:** Modern, faster, more secure than RSA

### `keys/ec-ssh-rpw.pub` (Legacy)
- **Type:** RSA
- **Algorithm:** RSA
- **Size:** 4096-bit
- **Note:** Kept for compatibility with older systems

## Security Features

All setup scripts include the following security measures:

- **Password Authentication:** Disabled by default
- **Public Key Authentication:** Enabled
- **SSH Directory Permissions:** 700 (drwx------)
- **Authorized Keys Permissions:** 600 (-rw-------)
- **Proper File Ownership:** All files owned by the `rpw` user

## Verification

After running the setup scripts, verify the installation:

```bash
# Check user exists
id rpw

# Check SSH directory permissions
ls -la /home/rpw/.ssh

# Check authorized keys content
cat /home/rpw/.ssh/authorized_keys

# Test SSH login (from another machine)
ssh -i path/to/private_key rpw@server_ip
```

## Troubleshooting

### "User already exists" warning
The script will prompt to update SSH keys for an existing user. This is safe to proceed.

### SSH login fails
1. Verify SSH service is running: `systemctl status sshd` or `systemctl status ssh`
2. Check SSH logs: `journalctl -u sshd` or `tail -f /var/log/auth.log`
3. Verify public key matches your private key
4. Check firewall settings allow SSH (port 22)

### Permission denied on sudo
- Verify the user was added to the correct sudo group (`sudo` or `wheel`)
- Check `/etc/sudoers.d/rpw` file exists with correct permissions (440)
- Run `sudo -l` as the user to verify sudo privileges

## License

This repository is for personal use. Keys and configurations are specific to the repository owner.
