# Podman Setup Guide

This guide covers detailed Podman installation and configuration for enterprise environments where Docker Desktop is restricted.

> **Looking for the quick start?** See the [main README](../README.md#path-podman) for basic Podman setup.

---

## Table of Contents

- [Installation](#installation)
- [Initialize and Start Podman](#initialize-and-start-podman)
- [Configure VS Code](#configure-vs-code)
- [Troubleshooting](#troubleshooting)

---

## Installation

| Platform | Install Command / Method |
|----------|-------------------------|
| **macOS** | `brew install podman` or download from [podman.io](https://podman.io/docs/installation#macos) |
| **Windows** | Download installer from [podman.io](https://podman.io/docs/installation#windows) or `winget install RedHat.Podman` |
| **Linux (Fedora/RHEL)** | `sudo dnf install podman` |
| **Linux (Ubuntu/Debian)** | `sudo apt-get install podman` |
| **Linux (Arch)** | `sudo pacman -S podman` |

Also install the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension in VS Code.

---

## Initialize and Start Podman

### macOS

```bash
# Initialize a Podman machine (only needed once)
podman machine init

# Start the machine
podman machine start

# Verify it's running
podman info
```

> **Apple Silicon (M1/M2/M3/M4):** Podman automatically uses the native `applehv` virtualization. No extra configuration needed.

### Windows

**Prerequisites:** WSL2 must be enabled. If not already enabled:

```powershell
# Run in PowerShell as Administrator
wsl --install

# Also enable Virtual Machine Platform (if not already)
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart your machine after these commands
```

After WSL2 is ready:

```powershell
# Initialize a Podman machine (only needed once)
podman machine init

# Start the machine
podman machine start

# Verify it's running
podman info
```

> **Using WSL2 backend:** Podman on Windows runs inside WSL2. If you encounter permission issues, try running from a WSL2 terminal.

### Linux (Rootless — Recommended)

```bash
# Enable and start the Podman socket for your user (rootless)
systemctl --user enable --now podman.socket

# Verify the socket is running
systemctl --user status podman.socket

# Find your socket path (you'll need this for VS Code)
echo "Socket path: /run/user/$(id -u)/podman/podman.sock"

# Verify Podman works
podman info
```

> **Note:** Rootless Podman is the recommended mode for most users. It runs containers without root privileges.

### Linux (Root mode — if required by your org)

```bash
# Enable and start the system-wide Podman socket
sudo systemctl enable --now podman.socket

# Verify it's running
sudo systemctl status podman.socket

# Socket will be at: /run/podman/podman.sock
```

---

## Configure VS Code

Open VS Code Settings (`Ctrl+,` or `Cmd+,`) and add these settings:

**All platforms:**
```json
{
  "dev.containers.dockerPath": "podman"
}
```

**Linux only (rootless) — also add:**
```json
{
  "dev.containers.dockerSocketPath": "/run/user/<YOUR_UID>/podman/podman.sock"
}
```
> ⚠️ Replace `<YOUR_UID>` with your actual user ID. Find it by running `id -u` in your terminal (commonly `1000` for the first user).

**Linux only (root mode) — also add:**
```json
{
  "dev.containers.dockerSocketPath": "/run/podman/podman.sock"
}
```

---

## Troubleshooting

### Container fails to start

1. Verify Podman is running:
   ```bash
   podman info
   ```
2. Check the socket path matches your VS Code settings
3. On macOS/Windows, ensure the machine is started:
   ```bash
   podman machine start
   ```

### Permission denied errors (Linux)

For rootless Podman, ensure the socket is enabled for your user:
```bash
systemctl --user enable --now podman.socket
```

If using SELinux, you may need to adjust labels:
```bash
# Add :Z suffix for SELinux volume relabeling
podman run -v ./mydir:/container/path:Z ...
```

### Podman machine won't start (Windows)

1. Ensure WSL2 is properly installed and enabled
2. Check Virtual Machine Platform is enabled:
   ```powershell
   # Run as Administrator
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
3. Restart your machine
4. Try initializing a fresh machine:
   ```bash
   podman machine rm podman-machine-default
   podman machine init
   podman machine start
   ```

### Enterprise proxy or CA certificate issues

Your organization may require custom CA certificates in the Podman VM.

**macOS/Windows:**
```bash
# SSH into the Podman machine
podman machine ssh

# Add your certificate (inside the VM)
sudo cp /path/to/your-ca-cert.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

**For detailed instructions:** See [Podman CA Certificate Guide](https://github.com/containers/podman/blob/main/docs/tutorials/podman-install-certificate-authority.md)

**Proxy configuration (if behind corporate proxy):**
```bash
# Set proxy for Podman machine
podman machine ssh
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=localhost,127.0.0.1
```

Or add to `~/.config/containers/containers.conf`:
```ini
[engine]
env = ["HTTP_PROXY=http://proxy.example.com:8080", "HTTPS_PROXY=http://proxy.example.com:8080"]
```

### Using podman-compose (alternative to Docker Compose)

If your environment doesn't support Docker Compose commands:
```bash
# Install podman-compose
pip install podman-compose

# Or on Fedora/RHEL
sudo dnf install podman-compose

# Use it like docker-compose
podman-compose up -d
```

> **Note:** The Dev Containers extension handles compose automatically when `dockerPath` is set to `podman`.

---

### Quick Reference: Common Podman Issues

| Problem | Quick Fix |
|---------|-----------|
| **WSL2/Virtual Machine Platform not enabled** (Windows) | Run in **PowerShell as Administrator**: `dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart` then `wsl --install`, restart |
| **Machine fails to start** (Windows/macOS) | Verify machine is initialized: `podman machine init` then `podman machine start` |
| **Socket not found** (Linux rootless) | Enable the Podman socket: `systemctl --user enable --now podman.socket` |
| **Socket not found** (Linux root) | Enable system socket: `sudo systemctl enable --now podman.socket` |
| **Dev Container fails with Podman** | Verify VS Code setting: `"dev.containers.dockerPath": "podman"`. On Linux rootless, also set `dockerSocketPath` — first run `id -u` to get your UID, then set: `"/run/user/<YOUR_UID>/podman/podman.sock"` |
| **Permission denied** (Linux) | For rootless, check socket ownership; for SELinux systems, use `:Z` volume suffix |
| **Corporate proxy issues** | Configure proxy in `~/.config/containers/containers.conf` or inside `podman machine ssh` |
| **CA certificate errors** | Add custom certs to Podman VM; see [Podman CA Certificate Guide](https://github.com/containers/podman/blob/main/docs/tutorials/podman-install-certificate-authority.md) |
