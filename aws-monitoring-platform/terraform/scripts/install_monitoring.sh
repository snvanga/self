#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo " Installing Prometheus + Grafana"
echo "=========================================="

apt-get update -y
apt-get upgrade -y
apt-get install -y wget curl tar gnupg apt-transport-https software-properties-common

PROMETHEUS_VERSION="2.45.0"
NODE_EXPORTER_VERSION="1.9.1"
GRAFANA_VERSION="13.1.3"

# Create Prometheus user
if ! id prometheus >/dev/null 2>&1; then
  useradd --no-create-home --shell /bin/false prometheus
fi

# Create Node Exporter user
if ! id node_exporter >/dev/null 2>&1; then
  useradd --no-create-home --shell /bin/false node_exporter
fi

# Node Exporter
echo "Installing Node Exporter..."
cd /tmp
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar -xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service <<'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Prometheus
echo "Installing Prometheus..."
mkdir -p /etc/prometheus /var/lib/prometheus
cd /tmp
wget -q "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
tar -xzf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
cp "prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus" /usr/local/bin/prometheus
cp "prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool" /usr/local/bin/promtool
cp -r "prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles" /etc/prometheus/
cp -r "prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries" /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

cat > /etc/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets:
          - "localhost:9090"
  - job_name: "node_exporter"
    static_configs:
      - targets:
          - "localhost:9100"
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus Monitoring Server
After=network.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Grafana
echo "Installing Grafana..."
mkdir -p /etc/apt/keyrings
wget -qO /tmp/grafana.key https://apt.grafana.com/gpg-full.key
mv /tmp/grafana.key /etc/apt/keyrings/grafana.asc
chmod 644 /etc/apt/keyrings/grafana.asc
printf '%s\n' "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -y

if ! apt-get install -y grafana; then
  echo "Grafana apt repo install failed; falling back to Grafana Enterprise .deb"
  apt-get install -y adduser libfontconfig1 musl || true
  GRAFANA_DEB="grafana-enterprise_${GRAFANA_VERSION}_amd64.deb"
  GRAFANA_URL="https://dl.grafana.com/grafana-enterprise/release/${GRAFANA_DEB}"
  cd /tmp
  wget -qO "${GRAFANA_DEB}" "${GRAFANA_URL}"
  apt-get install -y "./${GRAFANA_DEB}"
fi

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

if ! systemctl is-active --quiet grafana-server; then
  echo "Grafana failed to start"
  systemctl status grafana-server --no-pager || true
  journalctl -u grafana-server --no-pager | tail -n 40 || true
  exit 1
fi

# Final checks
systemctl is-active --quiet node_exporter
systemctl is-active --quiet prometheus
systemctl is-active --quiet grafana-server

echo "Grafana HTTP health:"
curl --fail --silent --show-error --max-time 10 http://localhost:3000/api/health

echo "Installation completed"
