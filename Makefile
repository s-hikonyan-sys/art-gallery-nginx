# Nginx設定ファイル検証用Makefile

.PHONY: help lint test

help:
	@echo "Available targets:"
	@echo "  lint  - Check nginx configuration syntax"
	@echo "  test  - Test nginx configuration (alias for lint)"

lint:
	@echo "Checking nginx configuration syntax..."
	@./.nginx-lint.sh nginx.conf

test: lint
