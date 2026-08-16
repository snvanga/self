#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "Installing Grafana only on Ubuntu..."

apt-get update -y
apt-get install -y wget curl gnupg apt-transport-https software-properties-common

mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
chmod 0644 /etc/apt/keyrings/grafana.gpg

cat > /etc/apt/sources.list.d/grafana.list <<'EOF'
deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main
EOF

apt-get update -y
apt-get install -y grafana

systemctl daemon-reload
systemctl enable --now grafana-server

if ! systemctl is-active --quiet grafana-server; then
  echo "Grafana failed to start"
  systemctl status grafana-server --no-pager || true
  journalctl -u grafana-server --no-pager | tail -n 50 || true
  exit 1
fi

curl --fail --silent --show-error --max-time 10 http://localhost:3000/api/health

touch /var/log/user-data-applied

echo "Grafana installation completed successfully"
exit 0