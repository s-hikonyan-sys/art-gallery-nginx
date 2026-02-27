# Nginx設定ファイル検証用Makefile

.PHONY: help lint test

help:
	@echo "Available targets:"
	@echo "  lint  - Check nginx configuration syntax"
	@echo "  test  - Test nginx configuration (alias for lint)"

lint:
	@echo "Checking nginx configuration syntax..."
	@if command -v docker >/dev/null 2>&1; then \
		docker run --rm \
			-v "$$(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro" \
			nginx:latest \
			nginx -t; \
	else \
		echo "Error: Docker not found. Please install Docker or use nginx -t manually."; \
		exit 1; \
	fi

test: lint
