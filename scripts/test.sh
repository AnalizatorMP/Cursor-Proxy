#!/usr/bin/env bash
set -euo pipefail

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Docker Compose not found" >&2
  exit 1
fi

"${COMPOSE[@]}" ps

if ! docker exec xray-ubuntu xray version >/dev/null 2>&1; then
  echo "xray is not responding inside the container" >&2
  exit 1
fi

if ! docker exec xray-ubuntu ss -ltnp | grep -q "10808"; then
  echo "SOCKS inbound not listening on 10808" >&2
  exit 1
fi

if ! docker exec xray-ubuntu ss -ltnp | grep -q "12345"; then
  echo "Transparent inbound not listening on 12345" >&2
  exit 1
fi

rules=$(docker exec xray-ubuntu iptables -t nat -S XRAY)

echo "$rules" | grep -q "172.64.0.0/24" || { echo "Missing iptables rule for 172.64.0.0/24" >&2; exit 1; }
echo "$rules" | grep -q "8.47.0.0/24" || { echo "Missing iptables rule for 8.47.0.0/24" >&2; exit 1; }

echo "All tests passed"
