#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo "======================================"
echo "Starting Monitoring Server Setup"
echo "======================================"
# =========================================================
# SYSTEM UPDATE
# =========================================================
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    wget \
    curl \
    tar \
    gnupg \
    apt-transport-https \
    software-properties-common
# =========================================================
# NODE EXPORTER
# =========================================================
echo "Installing Node Exporter..."
NODE_EXPORTER_VERSION="1.9.1"
if ! id node_exporter >/dev/null 2>&1; then
    useradd \
        --no-create-home \
        --shell /bin/false \
        node_exporter
fi
cd /tmp
wget -q \
"https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar -xzf \
"node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
cp \
"node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" \
/usr/local/bin/node_exporter
chown node_exporter:node_exporter \
/usr/local/bin/node_exporter
cat > /etc/systemd/system/node_exporter.service <<EOF
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
# =========================================================
# PROMETHEUS
# =========================================================
echo "Installing Prometheus..."
PROMETHEUS_VERSION="2.45.0"
if ! id prometheus >/dev/null 2>&1; then
    useradd \
        --no-create-home \
        --shell /bin/false \
        prometheus
fi
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
cd /tmp
wget -q \
"https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
tar -xzf \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
cp \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus" \
/usr/local/bin/prometheus
cp \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool" \
/usr/local/bin/promtool
cp -r \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles" \
/etc/prometheus/
cp -r \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries" \
/etc/prometheus/
chown -R prometheus:prometheus \
/etc/prometheus
chown -R prometheus:prometheus \
/var/lib/prometheus
# =========================================================
# PROMETHEUS CONFIGURATION
# =========================================================
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
  # Prometheus itself
  - job_name: "prometheus"
    static_configs:
      - targets:
          - "localhost:9090"
  # Node Exporter
  - job_name: "node_exporter"
    static_configs:
      - targets:
          - "localhost:9100"
EOF
chown prometheus:prometheus \
/etc/prometheus/prometheus.yml
# =========================================================
# PROMETHEUS SERVICE
# =========================================================
cat > /etc/systemd/system/prometheus.service <<EOF
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
# =========================================================
# GRAFANA
# =========================================================
echo "Installing Grafana..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
chmod 644 /etc/apt/keyrings/grafana.gpg
cat > /etc/apt/sources.list.d/grafana.list <<EOF
deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main
EOF
apt-get update -y
apt-get install -y grafana

if ! dpkg -l grafana >/dev/null 2>&1; then
  echo "Grafana package failed to install"
  apt-cache policy grafana || true
  ls -l /etc/apt/sources.list.d/grafana.list || true
  grep -R "grafana" /var/log/apt 2>/dev/null || true
  exit 1
fi

if [ ! -f /lib/systemd/system/grafana-server.service ] && [ ! -f /etc/systemd/system/grafana-server.service ]; then
  echo "Grafana systemd service file not found"
  ls -l /lib/systemd/system/grafana-server.service /etc/systemd/system/grafana-server.service 2>/dev/null || true
  exit 1
fi

# =========================================================
# START GRAFANA
# =========================================================
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# Verify Grafana service
if ! systemctl is-active --quiet grafana-server; then
  echo "Grafana service failed to start"
  systemctl status grafana-server --no-pager || true
  journalctl -u grafana-server --no-pager | tail -n 40 || true
  exit 1
fi

echo "Grafana service is active"

echo "Checking Grafana HTTP health on localhost:3000"
if ! curl --fail --silent --show-error --max-time 10 http://localhost:3000/api/health; then
  echo "Grafana HTTP health check failed"
  journalctl -u grafana-server --no-pager | tail -n 80 || true
  netstat -tlnp 2>/dev/null | grep 3000 || ss -tlnp | grep 3000 || true
  exit 1
fi

echo "Grafana HTTP health check passed"
# =========================================================
# WAIT
# =========================================================
sleep 15
# =========================================================
# CHECK SERVICES
# =========================================================
echo "======================================"
echo "Checking Node Exporter"
echo "======================================"
systemctl is-active node_exporter
echo "======================================"
echo "Checking Prometheus"
echo "======================================"
systemctl is-active prometheus
echo "======================================"
echo "Checking Grafana"
echo "======================================"
systemctl is-active grafana-server
echo "======================================"
echo "Monitoring Installation Completed"
echo "======================================"
