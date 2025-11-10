# Caddy Manager - Release Makefile
# Simplified Makefile for release packages

# Variables
APP_NAME = caddy-manager
PORT = $(shell grep -E '^PORT=' .env 2>/dev/null | cut -d '=' -f2 || echo "8000")
SERVICE_NAME = caddy-manager
SERVICE_FILE = /etc/systemd/system/$(SERVICE_NAME).service
WORK_DIR = $(shell pwd)
USER = $(shell whoami)

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Commands
.PHONY: help setup-sudo install-service uninstall-service start stop restart status logs clean

# Show help
help:
	@echo "$(GREEN)Caddy Manager - Release Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Available commands:$(NC)"
	@echo "  make setup-sudo        - Setup sudo permissions (requires sudo)"
	@echo "  make install-service   - Install systemd service (requires sudo)"
	@echo "  make uninstall-service - Uninstall systemd service (requires sudo)"
	@echo "  make start             - Start systemd service (requires sudo)"
	@echo "  make stop              - Stop systemd service (requires sudo)"
	@echo "  make restart           - Restart systemd service (requires sudo)"
	@echo "  make status            - Show service status"
	@echo "  make logs              - Show logs in real-time"
	@echo "  make clean             - Clean log files"
	@echo ""

# Setup sudo permissions
setup-sudo:
	@echo "$(RED)⚠️  WARNING: This command requires sudo privileges!$(NC)"
	@echo "$(YELLOW)Run with: sudo make setup-sudo$(NC)"
	@echo ""
	@if [ "$$(id -u)" -eq 0 ]; then \
		echo "$(GREEN)Setting up sudoers for Caddy Manager...$(NC)"; \
		CURRENT_USER=$$(who am i | awk '{print $$1}'); \
		if [ -z "$$CURRENT_USER" ]; then \
			CURRENT_USER=$$(logname); \
		fi; \
		if [ -z "$$CURRENT_USER" ]; then \
			echo "$(RED)✗ Cannot determine original user$(NC)"; \
			exit 1; \
		fi; \
		CADDYFILE_PATH=$${CADDYFILE_PATH:-/etc/caddy/Caddyfile}; \
		echo "$(GREEN)Configuring sudoers for user: $$CURRENT_USER$(NC)"; \
		echo "$(GREEN)Caddyfile path: $$CADDYFILE_PATH$(NC)"; \
		cat > /tmp/caddy-manager-sudoers << EOF; \
# Caddy Manager sudo rules \
$$CURRENT_USER ALL=(root) NOPASSWD: /usr/bin/caddy reload \
$$CURRENT_USER ALL=(root) NOPASSWD: /usr/bin/systemctl reload caddy \
$$CURRENT_USER ALL=(root) NOPASSWD: /usr/bin/systemctl restart caddy \
$$CURRENT_USER ALL=(root) NOPASSWD: /bin/cp $$CADDYFILE_PATH $$CADDYFILE_PATH.backup.* \
$$CURRENT_USER ALL=(root) NOPASSWD: /bin/cp /tmp/caddyfile_temp $$CADDYFILE_PATH \
$$CURRENT_USER ALL=(root) NOPASSWD: /usr/bin/cat $$CADDYFILE_PATH \
$$CURRENT_USER ALL=(root) NOPASSWD: /usr/bin/caddy validate --config $$CADDYFILE_PATH \
EOF; \
		if visudo -c -f /tmp/caddy-manager-sudoers; then \
			echo "$(GREEN)Adding rules to sudoers...$(NC)"; \
			cat /tmp/caddy-manager-sudoers >> /etc/sudoers.d/caddy-manager; \
			chmod 440 /etc/sudoers.d/caddy-manager; \
			echo "$(GREEN)✅ Setup completed!$(NC)"; \
			echo "$(GREEN)User $$CURRENT_USER can now:$(NC)"; \
			echo "  - Reload Caddy without password"; \
			echo "  - Create Caddyfile backups"; \
			echo "  - Update Caddyfile"; \
			echo "  - Validate Caddyfile"; \
		else \
			echo "$(RED)❌ Sudoers syntax error!$(NC)"; \
			exit 1; \
		fi; \
		rm /tmp/caddy-manager-sudoers; \
		echo ""; \
		echo "$(GREEN)To test, run:$(NC)"; \
		echo "  sudo caddy reload"; \
		echo "  sudo systemctl reload caddy"; \
	else \
		echo "$(RED)✗ This command must be run with sudo$(NC)"; \
		echo "$(YELLOW)Usage: sudo make setup-sudo$(NC)"; \
		exit 1; \
	fi

# Install systemd service
install-service:
	@echo "$(RED)⚠️  WARNING: This command requires sudo privileges!$(NC)"
	@echo "$(YELLOW)Run with: sudo make install-service$(NC)"
	@if [ "$$(id -u)" -eq 0 ]; then \
		echo "$(GREEN)Installing systemd service for Caddy Manager...$(NC)"; \
		if [ ! -f "$(WORK_DIR)/$(APP_NAME)" ]; then \
			echo "$(RED)✗ Binary $(APP_NAME) not found in $(WORK_DIR)$(NC)"; \
			exit 1; \
		fi; \
		ORIGINAL_USER=$$(who am i | awk '{print $$1}'); \
		if [ -z "$$ORIGINAL_USER" ]; then \
			ORIGINAL_USER=$$(logname); \
		fi; \
		if [ -z "$$ORIGINAL_USER" ]; then \
			echo "$(RED)✗ Cannot determine original user$(NC)"; \
			exit 1; \
		fi; \
		echo "$(GREEN)Creating systemd service file...$(NC)"; \
		printf '[Unit]\nDescription=Caddy Manager - Web interface for managing Caddyfile\nAfter=network.target\n\n[Service]\nType=simple\nUser=%s\nWorkingDirectory=%s\nExecStart=%s/%s\nRestart=always\nRestartSec=5\nStandardOutput=journal\nStandardError=journal\nSyslogIdentifier=%s\nEnvironmentFile=%s/.env\n\n[Install]\nWantedBy=multi-user.target\n' "$$ORIGINAL_USER" "$(WORK_DIR)" "$(WORK_DIR)" "$(APP_NAME)" "$(SERVICE_NAME)" "$(WORK_DIR)" > /tmp/$(SERVICE_NAME).service; \
		mv /tmp/$(SERVICE_NAME).service $(SERVICE_FILE); \
		chmod 644 $(SERVICE_FILE); \
		systemctl daemon-reload; \
		echo "$(GREEN)✅ Service installed successfully!$(NC)"; \
		echo "$(GREEN)Service file: $(SERVICE_FILE)$(NC)"; \
		echo "$(GREEN)User: $$ORIGINAL_USER$(NC)"; \
		echo "$(GREEN)Working directory: $(WORK_DIR)$(NC)"; \
		echo ""; \
		echo "$(YELLOW)To start the service, run:$(NC)"; \
		echo "  sudo make start"; \
		echo ""; \
		echo "$(YELLOW)To enable auto-start on boot, run:$(NC)"; \
		echo "  sudo systemctl enable $(SERVICE_NAME)"; \
	else \
		echo "$(RED)✗ This command must be run with sudo$(NC)"; \
		echo "$(YELLOW)Usage: sudo make install-service$(NC)"; \
		exit 1; \
	fi

# Uninstall systemd service
uninstall-service:
	@echo "$(RED)⚠️  WARNING: This command requires sudo privileges!$(NC)"
	@echo "$(YELLOW)Run with: sudo make uninstall-service$(NC)"
	@if [ "$$(id -u)" -eq 0 ]; then \
		echo "$(YELLOW)Uninstalling systemd service...$(NC)"; \
		if systemctl is-active --quiet $(SERVICE_NAME) 2>/dev/null; then \
			echo "$(YELLOW)Stopping service...$(NC)"; \
			systemctl stop $(SERVICE_NAME); \
		fi; \
		if systemctl is-enabled --quiet $(SERVICE_NAME) 2>/dev/null; then \
			echo "$(YELLOW)Disabling service...$(NC)"; \
			systemctl disable $(SERVICE_NAME); \
		fi; \
		if [ -f $(SERVICE_FILE) ]; then \
			rm -f $(SERVICE_FILE); \
			systemctl daemon-reload; \
			echo "$(GREEN)✅ Service uninstalled successfully!$(NC)"; \
		else \
			echo "$(YELLOW)Service file not found, nothing to remove$(NC)"; \
		fi; \
	else \
		echo "$(RED)✗ This command must be run with sudo$(NC)"; \
		echo "$(YELLOW)Usage: sudo make uninstall-service$(NC)"; \
		exit 1; \
	fi

# Start systemd service
start:
	@echo "$(RED)⚠️  WARNING: This command requires sudo privileges!$(NC)"
	@echo "$(YELLOW)Run with: sudo make start$(NC)"
	@if [ "$$(id -u)" -eq 0 ]; then \
		if [ ! -f $(SERVICE_FILE) ]; then \
			echo "$(RED)✗ Service not installed$(NC)"; \
			echo "$(YELLOW)Install it first: sudo make install-service$(NC)"; \
			exit 1; \
		fi; \
		echo "$(GREEN)Starting Caddy Manager service...$(NC)"; \
		mkdir -p $(WORK_DIR)/backups; \
		systemctl start $(SERVICE_NAME); \
		sleep 1; \
		if systemctl is-active --quiet $(SERVICE_NAME); then \
			echo "$(GREEN)✅ Service started successfully!$(NC)"; \
			echo "$(GREEN)✓ Status: $$(systemctl is-active $(SERVICE_NAME))$(NC)"; \
			echo "$(GREEN)✓ URL: http://localhost:$(PORT)$(NC)"; \
			echo "$(YELLOW)Check .env file for authentication credentials$(NC)"; \
			echo ""; \
			echo "$(YELLOW)To view logs: make logs$(NC)"; \
		else \
			echo "$(RED)✗ Failed to start service$(NC)"; \
			echo "$(YELLOW)Check logs: make logs$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)✗ This command must be run with sudo$(NC)"; \
		echo "$(YELLOW)Usage: sudo make start$(NC)"; \
		exit 1; \
	fi

# Stop systemd service
stop:
	@echo "$(RED)⚠️  WARNING: This command requires sudo privileges!$(NC)"
	@echo "$(YELLOW)Run with: sudo make stop$(NC)"
	@if [ "$$(id -u)" -eq 0 ]; then \
		if [ ! -f $(SERVICE_FILE) ]; then \
			echo "$(YELLOW)Service not installed$(NC)"; \
			exit 0; \
		fi; \
		echo "$(YELLOW)Stopping Caddy Manager service...$(NC)"; \
		if systemctl is-active --quiet $(SERVICE_NAME) 2>/dev/null; then \
			systemctl stop $(SERVICE_NAME); \
			echo "$(GREEN)✅ Service stopped$(NC)"; \
		else \
			echo "$(YELLOW)Service is not running$(NC)"; \
		fi; \
	else \
		echo "$(RED)✗ This command must be run with sudo$(NC)"; \
		echo "$(YELLOW)Usage: sudo make stop$(NC)"; \
		exit 1; \
	fi

# Restart systemd service
restart:
	@echo "$(RED)⚠️  WARNING: This command requires sudo privileges!$(NC)"
	@echo "$(YELLOW)Run with: sudo make restart$(NC)"
	@if [ "$$(id -u)" -eq 0 ]; then \
		if [ ! -f $(SERVICE_FILE) ]; then \
			echo "$(RED)✗ Service not installed$(NC)"; \
			echo "$(YELLOW)Install it first: sudo make install-service$(NC)"; \
			exit 1; \
		fi; \
		echo "$(GREEN)Restarting Caddy Manager service...$(NC)"; \
		systemctl restart $(SERVICE_NAME); \
		sleep 1; \
		if systemctl is-active --quiet $(SERVICE_NAME); then \
			echo "$(GREEN)✅ Service restarted successfully!$(NC)"; \
			echo "$(GREEN)✓ Status: $$(systemctl is-active $(SERVICE_NAME))$(NC)"; \
		else \
			echo "$(RED)✗ Failed to restart service$(NC)"; \
			echo "$(YELLOW)Check logs: make logs$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)✗ This command must be run with sudo$(NC)"; \
		echo "$(YELLOW)Usage: sudo make restart$(NC)"; \
		exit 1; \
	fi

# Show service status
status:
	@echo "$(GREEN)Caddy Manager service status:$(NC)"
	@if [ -f $(SERVICE_FILE) ]; then \
		systemctl status $(SERVICE_NAME) --no-pager -l || true; \
		echo ""; \
		if systemctl is-active --quiet $(SERVICE_NAME) 2>/dev/null; then \
			echo "$(GREEN)✓ Service is running$(NC)"; \
			echo "$(GREEN)✓ Port: $(PORT)$(NC)"; \
			echo "$(GREEN)✓ URL: http://localhost:$(PORT)$(NC)"; \
		else \
			echo "$(RED)✗ Service is not running$(NC)"; \
		fi; \
	else \
		echo "$(RED)✗ Service not installed$(NC)"; \
		echo "$(YELLOW)Install it first: sudo make install-service$(NC)"; \
	fi

# Show logs
logs:
	@if [ -f $(SERVICE_FILE) ]; then \
		echo "$(GREEN)Recent Caddy Manager logs (press Ctrl+C to exit):$(NC)"; \
		journalctl -u $(SERVICE_NAME) -f --no-pager; \
	else \
		echo "$(RED)✗ Service not installed$(NC)"; \
		echo "$(YELLOW)Install it first: sudo make install-service$(NC)"; \
	fi

# Clean logs
clean:
	@echo "$(YELLOW)Cleaning Caddy Manager journal logs...$(NC)"
	@if [ -f $(SERVICE_FILE) ]; then \
		if [ "$$(id -u)" -eq 0 ]; then \
			journalctl -u $(SERVICE_NAME) --vacuum-time=1s > /dev/null 2>&1 || true; \
			echo "$(GREEN)✓ Cleaned journal logs$(NC)"; \
		else \
			echo "$(YELLOW)Note: Cleaning journal logs requires sudo$(NC)"; \
			echo "$(YELLOW)Run: sudo journalctl -u $(SERVICE_NAME) --vacuum-time=1s$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)Service not installed, nothing to clean$(NC)"; \
	fi 