# SSH Public Keys

This directory contains SSH public keys used for remote server authentication.

## Key Files

### `ssh-rpw.pub` (Recommended)
- **Type:** ed25519
- **Algorithm:** EdDSA
- **Size:** 256-bit
- **Created:** Modern key type

**Advantages:**
- Smaller key size
- Faster operations
- Better security properties
- Modern standard (recommended by OpenSSH developers)

**Use this key for:**
- New server setups
- All modern systems (OpenSSH 6.5+ from 2014)
- Primary authentication method

### `ec-ssh-rpw.pub` (Legacy)
- **Type:** RSA
- **Algorithm:** RSA
- **Size:** 4096-bit
- **Created:** Legacy key type

**Use this key for:**
- Very old systems that don't support ed25519
- Compatibility with legacy infrastructure
- Backup authentication method

**Note:** This key is kept for backward compatibility only. Use `ssh-rpw.pub` for new installations.

## Security Notes

- These are **public keys only** - they can be safely shared
- Never commit or share private keys
- Keys in this directory are used by setup scripts to configure remote servers
- Regular rotation of keys is recommended for best security practices

## Key Management

To add a new SSH key:

1. Generate a new key pair:
   ```bash
   ssh-keygen -t ed25519 -C "comment" -f ~/.ssh/new_key
   ```

2. Copy the public key to this directory:
   ```bash
   cp ~/.ssh/new_key.pub /path/to/repo/keys/
   ```

3. Update the setup scripts to use the new key if needed

4. Commit and push to GitHub

## Key Fingerprint Verification

To verify key fingerprints:

```bash
# For ssh-rpw.pub (ed25519)
ssh-keygen -lf keys/ssh-rpw.pub

# For ec-ssh-rpw.pub (RSA)
ssh-keygen -lf keys/ec-ssh-rpw.pub
```

## Troubleshooting

### Key not working on server
1. Verify SSH server supports the key type
   - ed25519: OpenSSH 6.5+ (2014)
   - RSA: All SSH versions

2. Check SSH server configuration:
   ```bash
   grep -E "^(PubkeyAuthentication|AuthorizedKeysFile)" /etc/ssh/sshd_config
   ```

3. Verify key permissions:
   - Directory: `700 (drwx------)`
   - Authorized keys file: `600 (-rw-------)`

4. Check SSH logs for errors:
   - Debian/Ubuntu: `tail -f /var/log/auth.log`
   - RHEL/CentOS: `tail -f /var/log/secure`
