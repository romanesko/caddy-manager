# Caddy Manager

Web application for managing Caddyfile with a beautiful Tabler UI interface.

## 📦 Downloads

### Latest Release: [v1.0.1](https://github.com/romanesko/caddy-manager/releases/tag/v1.0.1)

**Pre-built binaries:**
- **Linux AMD64**: [caddy-manager-linux-amd64.tar.gz](https://github.com/romanesko/caddy-manager/releases/download/v1.0.1/caddy-manager-linux-amd64.tar.gz)
- **Linux ARM64**: [caddy-manager-linux-arm64.tar.gz](https://github.com/romanesko/caddy-manager/releases/download/v1.0.1/caddy-manager-linux-arm64.tar.gz)
- **macOS AMD64**: [caddy-manager-darwin-amd64.tar.gz](https://github.com/romanesko/caddy-manager/releases/download/v1.0.1/caddy-manager-darwin-amd64.tar.gz)
- **macOS ARM64**: [caddy-manager-darwin-arm64.tar.gz](https://github.com/romanesko/caddy-manager/releases/download/v1.0.1/caddy-manager-darwin-arm64.tar.gz)

**All releases:** [GitHub Releases](https://github.com/romanesko/caddy-manager/releases)

## 🚀 Technologies

- **Frontend**: Vanilla JavaScript + Tabler UI
- **Backend**: Go + Gin Framework
- **Interface**: Modern web interface with table representation

## 🎯 Features

- 📝 Edit Caddyfile through a convenient table
- 💾 Automatic backup creation before changes
- 🔄 Restart Caddy server
- 📋 View and restore backups
- 🔍 Real-time port status checking
- 🔐 Basic authentication
- 📱 Responsive design with Tabler UI
- ✅ Syntax validation before applying
- 📚 Compliance with official Caddyfile standards

## Installation

### Quick Start (Pre-built Binaries)

Download the latest release for your platform from [GitHub Releases](https://github.com/romanesko/caddy-manager/releases):

1. **Download** the appropriate package for your platform
2. **Extract** the archive
3. **Make executable** (Linux/macOS):
   ```bash
   chmod +x caddy-manager
   ```
4. **Configure** environment:
   ```bash
   cp env.example .env
   # Edit .env with your settings
   ```
5. **Setup sudo** (if needed):
   ```bash
   sudo make setup-sudo
   ```
6. **Run**:
   ```bash
   # Start in background
   make start
   
   # Or run directly
   ./caddy-manager
   ```

### From Source

#### Requirements

- Go 1.21 or higher
- Caddy server
- Write permissions to `/etc/caddy/Caddyfile`

#### Installation Steps

1. Clone the repository:
```bash
git clone <repository-url>
cd caddy-manager
```

2. Install dependencies:
```bash
go mod tidy
```

3. Create and configure `.env` file:
```bash
cp env.example .env
# Edit .env file according to your needs
```

4. Configure environment variables in `.env`:
```env
CADDYFILE_PATH=/etc/caddy/Caddyfile
BACKUP_DIR=./backups
PORT=8000
AUTH_USERNAME=admin
AUTH_PASSWORD=admin123
```

5. Create backup directory:
```bash
mkdir -p backups
```

6. **Setup sudo permissions (required for production):**
```bash
sudo make setup-sudo
```
Details in [SUDO_SETUP.md](SUDO_SETUP.md)

7. Start the application:
```bash
# Development mode
make dev

# Or in background mode
make start
```

The application will be available at `http://localhost:8000`

**Important**: You will need to enter the login and password specified in the environment variables to access the application.

### Makefile Commands (Development)

- `make setup-sudo` - Setup sudo permissions (requires sudo)
- `make build` - Build application
- `make dev` - Run in development mode
- `make start` - Start in background mode
- `make stop` - Stop application
- `make restart` - Restart application
- `make status` - Show application status

### Release Makefile Commands

The release package includes `Makefile` with simplified commands:

- `make setup-sudo` - Setup sudo permissions (requires sudo)
- `make start` - Start application in background
- `make stop` - Stop application
- `make restart` - Restart application
- `make status` - Show application status
- `make logs` - Show logs in real-time
- `make clean` - Clean logs and PID files
- `make logs` - Show logs in real-time
- `make clean` - Clean built files

## Usage

### Main Features

1. **Editing**: Open the web interface and edit Caddyfile in the table editor
2. **Saving**: Click "Save" button to save changes (backup is automatically created)
3. **Restart**: Click "Restart Caddy" to apply changes
4. **Backups**: Use the "Backups" tab to view and restore previous versions

### API Endpoints

- `GET /api/caddyfile` - Get Caddyfile content
- `POST /api/caddyfile` - Save Caddyfile
- `POST /api/restart` - Restart Caddy
- `GET /api/backups` - Get list of backups
- `POST /api/backup` - Create new backup
- `GET /api/backup/:id` - Get backup content
- `POST /api/restore/:id` - Restore backup
- `GET /api/check-ports` - Check status of all ports

## 📚 Caddyfile Standards Support

The application fully complies with the [official Caddyfile documentation](https://caddyserver.com/docs/caddyfile/concepts) and supports:

### ✅ Supported Concepts:

- **Global Options** - `{ }` block at the beginning of the file
- **Snippets** - named blocks `(name) { }`
- **Site Blocks** - main content with addresses and directives
- **Comments** - start with `#`
- **Directives** - `reverse_proxy`, `file_server`, `request_body`, `transport`
- **Subdirectives** - `max_size`, `read_timeout`, `root *`
- **Imports** - `import` directives for snippets

### 🔧 Caddyfile Parser:

- Correctly processes nested blocks
- Ignores global options and snippets when extracting domains
- Correctly extracts ports from `reverse_proxy` directives
- Supports complex configurations with `request_body` and `transport`

### 📖 Examples:

In the `examples/` directory you will find examples of various configurations:

- `complex-caddyfile` - Demonstrates all supported capabilities:
  - Global options
  - Snippets for logging and security
  - Various site types (file_server, reverse_proxy)
  - Complex configurations with timeouts
  - Multiple addresses and subdomains

## Security

⚠️ **Important**: The application requires write permissions to system files. It is recommended to:

- Run with minimal necessary privileges
- **Always configure AUTH_USERNAME and AUTH_PASSWORD in .env**
- Use strong passwords for production
- Regularly check backups
- Use HTTPS in production
- Restrict port access to trusted IP addresses only

## Development

### Project Structure

```
caddy-manager/
├── main.go              # Main application file
├── handlers.go          # API handlers
├── auth.go              # Authentication and security
├── go.mod               # Go modules
├── env.example          # Configuration example
├── Makefile             # Management commands
├── SUDO_SETUP.md        # Sudo setup documentation
├── static/              # Static files
│   └── index.html       # Web interface (Vanilla JS + Tabler UI)
├── backups/             # Backup directory
└── README.md            # Documentation
```

### Building

```bash
go build -o caddy-manager .
```

### Running in Production

```bash
./caddy-manager
```

## License

MIT License 