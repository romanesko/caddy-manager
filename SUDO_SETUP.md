# Sudo Setup for Caddy Manager

## Problem
Caddy Manager requires sudo privileges for:
- Reading `/etc/caddy/Caddyfile`
- Writing to `/etc/caddy/Caddyfile`
- Restarting Caddy server
- Creating backups

## Solution

### 1. Automatic Setup (Recommended)

```bash
# Run setup command with sudo
sudo make setup-sudo
```

### 2. Manual Setup

Create file `/etc/sudoers.d/caddy-manager`:

```bash
sudo visudo -f /etc/sudoers.d/caddy-manager
```

Add the following lines (replace `YOUR_USERNAME` with your username):

```
# Caddy Manager sudo rules
YOUR_USERNAME ALL=(root) NOPASSWD: /usr/bin/caddy reload
YOUR_USERNAME ALL=(root) NOPASSWD: /usr/bin/systemctl reload caddy
YOUR_USERNAME ALL=(root) NOPASSWD: /usr/bin/systemctl restart caddy
YOUR_USERNAME ALL=(root) NOPASSWD: /bin/cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.*
YOUR_USERNAME ALL=(root) NOPASSWD: /bin/cp /tmp/caddyfile_temp /etc/caddy/Caddyfile
YOUR_USERNAME ALL=(root) NOPASSWD: /usr/bin/cat /etc/caddy/Caddyfile
YOUR_USERNAME ALL=(root) NOPASSWD: /usr/bin/caddy validate --config /etc/caddy/Caddyfile
```

### 3. Verify Setup

```bash
# Check that sudo works without password
sudo caddy reload
sudo systemctl reload caddy
sudo cat /etc/caddy/Caddyfile
```

## Alternative Solutions

### Option 1: Run application with sudo
```bash
sudo ./caddy-manager
```
⚠️ **Not recommended** - application will run with root privileges

### Option 2: Change Caddyfile permissions
```bash
sudo chown $USER:$USER /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile
```
⚠️ **Not recommended** - may compromise security

### Option 3: Use ACL
```bash
sudo setfacl -m u:$USER:rw /etc/caddy/Caddyfile
```
⚠️ **Requires ACL support in filesystem**

## Security

- Sudo rules are limited to necessary commands only
- `NOPASSWD` is used only for specific commands
- Temporary files are created in `/tmp` and automatically cleaned up
- All operations are logged in system journal

## Troubleshooting

### Error "sudo: no tty present and no askpass program specified"
Add to sudoers:
```
Defaults:YOUR_USERNAME !requiretty
```

### Error "command not found"
Check command paths:
```bash
which caddy
which systemctl
```

### File access error
Check Caddyfile permissions:
```bash
ls -la /etc/caddy/Caddyfile
``` 