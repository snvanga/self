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
wget -q -O \
/etc/apt/keyrings/grafana.asc \
https://apt.grafana.com/gpg-full.key
chmod 644 \
/etc/apt/keyrings/grafana.asc
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" \
> /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y grafana
# =========================================================
# START GRAFANA
# =========================================================
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
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
