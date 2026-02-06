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

required=(
  "13.107.0.0/16"
  "18.66.0.0/16"
  "20.118.0.0/16"
  "23.35.0.0/16"
  "104.18.0.0/16"
  "142.250.0.0/16"
  "172.64.0.0/16"
  "184.105.0.0/16"
  "188.114.0.0/16"
)

for cidr in "${required[@]}"; do
  echo "$rules" | grep -q "$cidr" || { echo "Missing iptables rule for $cidr" >&2; exit 1; }
done

if docker exec xray-ubuntu getent ahosts ifconfig.me >/dev/null 2>&1; then
  ips=$(docker exec xray-ubuntu getent ahosts ifconfig.me | awk '{print $1}' | grep -E '^[0-9]+\\.' | sort -u)
  matched=0
  for ip in $ips; do
    if echo "$rules" | grep -q "${ip}/32"; then
      matched=1
      break
    fi
  done
  if [[ "$matched" -eq 0 ]]; then
    echo "Missing iptables rule for ifconfig.me IPs" >&2
    exit 1
  fi
fi

echo "All tests passed"
