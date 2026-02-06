#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not in PATH" >&2
  exit 1
fi

docker info >/dev/null 2>&1 || { echo "Docker daemon is not running" >&2; exit 1; }

if docker compose version >/dev/null 2>&1; then
  echo "docker compose detected"
elif command -v docker-compose >/dev/null 2>&1; then
  echo "docker-compose detected"
else
  echo "Docker Compose not found. Install Docker Desktop or docker-compose." >&2
  exit 1
fi

if [[ -f "${PWD}/docker-compose.yml" ]]; then
  echo "docker-compose.yml found"
else
  echo "docker-compose.yml not found in ${PWD}" >&2
  exit 1
fi
