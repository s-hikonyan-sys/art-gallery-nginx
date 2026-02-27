#!/bin/bash
# Nginx設定ファイルの構文チェックスクリプト

set -e

NGINX_CONF="${1:-nginx.conf}"
NGINX_BIN="${NGINX_BIN:-nginx}"

echo "Checking nginx configuration: ${NGINX_CONF}"

# コンテナ内でnginx -tを実行
if command -v docker >/dev/null 2>&1; then
    # nginxコンテナを使用して構文チェック
    docker run --rm \
        -v "$(pwd)/${NGINX_CONF}:/etc/nginx/nginx.conf:ro" \
        nginx:latest \
        nginx -t
else
    # ローカルのnginxを使用
    if command -v "${NGINX_BIN}" >/dev/null 2>&1; then
        "${NGINX_BIN}" -t -c "$(pwd)/${NGINX_CONF}"
    else
        echo "Error: nginx not found. Please install nginx or use Docker."
        exit 1
    fi
fi

echo "✓ nginx configuration is valid"

