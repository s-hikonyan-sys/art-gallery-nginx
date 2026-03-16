#!/bin/bash
# Nginx設定ファイルの構文チェックスクリプト

set -euo pipefail

NGINX_CONF="${1:-nginx.conf}"
NGINX_BIN="${NGINX_BIN:-nginx}"

log_info() {
  echo "$(date -Is) INFO: ${1}"
}

log_error() {
  echo "$(date -Is) ERROR: ${1}" >&2
}

create_temp_config() {
  local -r source_conf="${1}"
  local -r temp_conf

  temp_conf="$(mktemp /tmp/nginx.conf.lint.XXXXXX)"
  cp "${source_conf}" "${temp_conf}"

  # CI環境では backend:8080 というDockerネットワーク上のホストは存在しないため、
  # lint専用の一時ファイルでは 127.0.0.1:8080 に置き換えて名前解決エラーを回避する。
  if sed -i 's/backend:8080/127.0.0.1:8080/g' "${temp_conf}"; then
    log_info "Temporarily replaced 'backend:8080' with '127.0.0.1:8080' for linting."
  else
    log_error "Failed to rewrite upstream host in temporary nginx.conf. Proceeding as is."
  fi

  echo "${temp_conf}"
}

run_docker_lint() {
  local -r lint_conf="${1}"

  docker run --rm \
    -v "${lint_conf}:/etc/nginx/nginx.conf:ro" \
    nginx:latest \
    nginx -t
}

run_local_lint() {
  local -r lint_conf="${1}"

  if command -v "${NGINX_BIN}" >/dev/null 2>&1; then
    "${NGINX_BIN}" -t -c "${lint_conf}"
  else
    log_error "Error: nginx not found. Please install nginx or use Docker."
    exit 1
  fi
}

main() {
  log_info "Checking nginx configuration: ${NGINX_CONF}"

  local temp_conf
  temp_conf="$(create_temp_config "${NGINX_CONF}")"

  if command -v docker >/dev/null 2>&1; then
    run_docker_lint "${temp_conf}"
  else
    run_local_lint "${temp_conf}"
  fi

  rm -f "${temp_conf}"

  log_info "✓ nginx configuration is valid"
}

main "$@"

