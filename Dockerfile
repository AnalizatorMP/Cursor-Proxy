FROM ubuntu:22.04

ARG XRAY_VERSION=26.1.13
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      unzip \
      iproute2 \
      iptables \
      jq; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) xray_arch="64" ;; \
      arm64) xray_arch="arm64-v8a" ;; \
      armhf) xray_arch="arm32-v7a" ;; \
      *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${xray_arch}.zip" -o /tmp/xray.zip; \
    unzip /tmp/xray.zip -d /tmp/xray; \
    install -m 755 /tmp/xray/xray /usr/local/bin/xray; \
    install -m 644 /tmp/xray/geoip.dat /usr/local/share/xray/geoip.dat; \
    install -m 644 /tmp/xray/geosite.dat /usr/local/share/xray/geosite.dat; \
    rm -rf /tmp/xray /tmp/xray.zip

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
