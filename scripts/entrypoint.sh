#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${XRAY_CONFIG:-/etc/xray/config.json}"
TPROXY_PORT="${XRAY_TRANSPARENT_PORT:-12345}"
ROUTE_CIDRS=()
if [[ -n "${XRAY_ROUTE_CIDRS:-}" ]]; then
  IFS=' ' read -r -a ROUTE_CIDRS <<< "${XRAY_ROUTE_CIDRS}"
fi
ROUTE_DOMAINS=()
if [[ -n "${XRAY_ROUTE_DOMAINS:-}" ]]; then
  IFS=' ' read -r -a ROUTE_DOMAINS <<< "${XRAY_ROUTE_DOMAINS}"
fi
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

# Resolve domains to IPs and append to CIDR list
if (( ${#ROUTE_DOMAINS[@]} > 0 )); then
  for domain in "${ROUTE_DOMAINS[@]}"; do
    while read -r ip _; do
      [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
      ROUTE_CIDRS+=("${ip}/32")
    done < <(getent ahosts "$domain" | sort -u)
  done
fi

if (( ${#ROUTE_CIDRS[@]} == 0 )); then
  echo "No route CIDRs or domains configured (XRAY_ROUTE_CIDRS / XRAY_ROUTE_DOMAINS)" >&2
  exit 1
fi

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
