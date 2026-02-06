#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${XRAY_CONFIG:-/etc/xray/config.json}"
TPROXY_PORT="${XRAY_TRANSPARENT_PORT:-12345}"
IFS=' ' read -r -a ROUTE_CIDRS <<< "${XRAY_ROUTE_CIDRS:-172.64.0.0/24 8.47.0.0/24}"
CHAIN="XRAY"

if ! command -v xray >/dev/null 2>&1; then
  echo "xray binary not found in PATH" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "xray config not found: $CONFIG_PATH" >&2
  exit 1
fi

# Validate config before starting
xray run -test -c "$CONFIG_PATH"

# Setup iptables rules for selected CIDRs
iptables -t nat -N "$CHAIN" 2>/dev/null || true
iptables -t nat -F "$CHAIN"

for cidr in "${ROUTE_CIDRS[@]}"; do
  iptables -t nat -A "$CHAIN" -p tcp -d "$cidr" -j REDIRECT --to-ports "$TPROXY_PORT"
  iptables -t nat -A "$CHAIN" -p udp -d "$cidr" -j REDIRECT --to-ports "$TPROXY_PORT"
done

iptables -t nat -C OUTPUT -p tcp -j "$CHAIN" 2>/dev/null || iptables -t nat -A OUTPUT -p tcp -j "$CHAIN"
iptables -t nat -C OUTPUT -p udp -j "$CHAIN" 2>/dev/null || iptables -t nat -A OUTPUT -p udp -j "$CHAIN"

exec xray run -c "$CONFIG_PATH"
