# Caddy Manager - Release Makefile
# Simplified Makefile for release packages

# Variables
APP_NAME = caddy-manager
PORT = 8000
PID_FILE = .pid
LOG_FILE = caddy-manager.log

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Commands
.PHONY: help setup-sudo start stop restart status logs clean

# Show help
help:
	@echo "$(GREEN)Caddy Manager - Release Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Available commands:$(NC)"
	@echo "  make setup-sudo     - Setup sudo permissions (requires sudo)"
	@echo "  make start          - Start application in background"
	@echo "  make stop           - Stop application"
	@echo "  make restart        - Restart application"
	@echo "  make status         - Show application status"
	@echo "  make logs           - Show logs in real-time"
	@echo "  make clean          - Clean logs and PID files"
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

# Start application in background
start:
	@echo "$(GREEN)Starting Caddy Manager in background...$(NC)"
	@mkdir -p backups
	@if [ -f .env ]; then \
		export $$(cat .env | xargs); \
	else \
		echo "$(YELLOW).env file not found, using default values$(NC)"; \
		export CADDYFILE_PATH=./test-caddyfile; \
		export PORT=$(PORT); \
	fi; \
	nohup ./$(APP_NAME) > $(LOG_FILE) 2>&1 & echo $$! > $(PID_FILE)
	@PID=$$(cat $(PID_FILE)); \
	echo "$(GREEN)✓ Caddy Manager started with PID: $$PID$(NC)"; \
	echo "$(GREEN)✓ Logs: $(LOG_FILE)$(NC)"; \
	echo "$(GREEN)✓ URL: http://localhost:$(PORT)$(NC)"; \
	echo "$(YELLOW)Check .env file for authentication credentials$(NC)"

# Stop application
stop:
	@echo "$(YELLOW)Stopping Caddy Manager...$(NC)"
	@if [ -f $(PID_FILE) ]; then \
		PID=$$(cat $(PID_FILE)); \
		if ps -p $$PID > /dev/null 2>&1; then \
			kill $$PID; \
			echo "$(GREEN)✓ Process $$PID stopped$(NC)"; \
		else \
			echo "$(YELLOW)Process $$PID not running$(NC)"; \
		fi; \
		rm -f $(PID_FILE); \
	else \
		echo "$(YELLOW)PID file not found, trying to find process on port $(PORT)...$(NC)"; \
		PID=$$(lsof -ti:$(PORT) 2>/dev/null || echo ""); \
		if [ -n "$$PID" ]; then \
			echo "$(YELLOW)Found process $$PID on port $(PORT), stopping...$(NC)"; \
			kill $$PID; \
			echo "$(GREEN)✓ Process $$PID stopped$(NC)"; \
		else \
			echo "$(YELLOW)No process found on port $(PORT)$(NC)"; \
		fi; \
	fi

# Restart application
restart: stop start

# Show application status
status:
	@echo "$(GREEN)Caddy Manager status:$(NC)"
	@if [ -f $(PID_FILE) ]; then \
		PID=$$(cat $(PID_FILE)); \
		if ps -p $$PID > /dev/null 2>&1; then \
			echo "$(GREEN)✓ Running with PID: $$PID$(NC)"; \
			echo "$(GREEN)✓ Port: $(PORT)$(NC)"; \
			echo "$(GREEN)✓ URL: http://localhost:$(PORT)$(NC)"; \
		else \
			echo "$(RED)✗ Process $$PID not running$(NC)"; \
			rm -f $(PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)PID file not found$(NC)"; \
		PID=$$(lsof -ti:$(PORT) 2>/dev/null || echo ""); \
		if [ -n "$$PID" ]; then \
			echo "$(YELLOW)Found process $$PID on port $(PORT) (not started via make)$(NC)"; \
		else \
			echo "$(RED)✗ Application not running$(NC)"; \
		fi; \
	fi

# Show logs
logs:
	@if [ -f $(LOG_FILE) ]; then \
		echo "$(GREEN)Recent Caddy Manager logs:$(NC)"; \
		tail -f $(LOG_FILE); \
	else \
		echo "$(YELLOW)Log file not found$(NC)"; \
		echo "$(YELLOW)Start the application first: make start$(NC)"; \
	fi

# Clean logs and PID files
clean:
	@echo "$(YELLOW)Cleaning Caddy Manager files...$(NC)"
	@rm -f $(PID_FILE) $(LOG_FILE)
	@echo "$(GREEN)✓ Cleaned PID and log files$(NC)" 