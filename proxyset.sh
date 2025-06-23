#!/usr/bin/env bash
set -euo pipefail

# This script configures APT to use your HTTP/HTTPS proxy.

PROXY_URL="http://ufproxy.b.cii.u-fukui.ac.jp:8080"
APT_CONF_DIR="/etc/apt/apt.conf.d"
PROXY_CONF="${APT_CONF_DIR}/01proxy"

# Ensure the directory exists
if [ ! -d "${APT_CONF_DIR}" ]; then
  echo "Creating ${APT_CONF_DIR}…"
  mkdir -p "${APT_CONF_DIR}"
fi

# Write the proxy config
cat <<EOF > "${PROXY_CONF}"
Acquire::http::Proxy "${PROXY_URL}";
Acquire::https::Proxy "${PROXY_URL}";
EOF

# Set safe permissions
chmod 644 "${PROXY_CONF}"

echo "Wrote APT proxy settings to ${PROXY_CONF}"
echo "Now updating package lists…"
apt-get update
