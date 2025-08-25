.PHONY: install start dev benchmark setup-nginx restart-nginx setup-hosts install-deps help

help:
	@echo "Available commands:"
	@echo "  make install      - Install Node.js dependencies"
	@echo "  make start        - Start the Node.js server"
	@echo "  make dev          - Start the Node.js server with hot reload"
	@echo "  make benchmark    - Run benchmark tests"
	@echo "  make setup-nginx  - Configure and start Nginx with custom config (requires sudo)"
	@echo "  make restart-nginx - Restart Nginx with custom configuration after changes (requires sudo)"
	@echo "  make setup-hosts  - Configure /etc/hosts for node-latency-demo (requires sudo)"
	@echo "  make install-deps - Install system dependencies (Ubuntu/Debian)"
	@echo "  make help         - Show this help message"

install:
	npm install

start:
	npm start

dev:
	npm run dev

benchmark:
	./scripts/load-test.sh

setup-nginx:
	@echo "Setting up Nginx with direct configuration approach..."
	@echo "This requires sudo access"
	sudo nginx -s stop || true
	sudo nginx -c $(PWD)/config/nginx.conf
	@echo "Nginx configured successfully. Now listening on port 80."
	@echo "Test with: curl http://localhost/health"

restart-nginx:
	@echo "Restarting Nginx with custom configuration..."
	./scripts/restart-nginx.sh

install-deps:
	@echo "Installing system dependencies..."
	@echo "This requires sudo access"
	sudo apt-get update
	sudo apt-get install -y nodejs npm nginx apache2-utils
	@echo "System dependencies installed successfully" 