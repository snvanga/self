#!/bin/bash

set -e

echo "=========================================="
echo " Installing Prometheus + Grafana"
echo "=========================================="

# --------------------------------------------------
# Update Ubuntu
# --------------------------------------------------

sudo apt update
sudo apt upgrade -y

sudo apt install -y wget curl tar gnupg apt-transport-https software-properties-common


# --------------------------------------------------
# Variables
# --------------------------------------------------

PROMETHEUS_VERSION="3.5.0"
NODE_EXPORTER_VERSION="1.9.1"


# --------------------------------------------------
# Create Prometheus user
# --------------------------------------------------

if ! id prometheus >/dev/null 2>&1; then
    sudo useradd \
        --no-create-home \
        --shell /bin/false \
        prometheus
fi


# --------------------------------------------------
# Create Node Exporter user
# --------------------------------------------------

if ! id node_exporter >/dev/null 2>&1; then
    sudo useradd \
        --no-create-home \
        --shell /bin/false \
        node_exporter
fi


# ==================================================
# NODE EXPORTER
# ==================================================

echo "Installing Node Exporter..."

cd /tmp

wget -q \
"https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

tar -xzf \
"node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

sudo cp \
"node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" \
/usr/local/bin/node_exporter

sudo chown node_exporter:node_exporter \
/usr/local/bin/node_exporter


# Node Exporter service

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
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


sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter


# ==================================================
# PROMETHEUS
# ==================================================

echo "Installing Prometheus..."

sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus

cd /tmp

wget -q \
"https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

tar -xzf \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

sudo cp \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus" \
/usr/local/bin/prometheus

sudo cp \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool" \
/usr/local/bin/promtool

sudo cp -r \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles" \
/etc/prometheus/

sudo cp -r \
"prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries" \
/etc/prometheus/


# Permissions

sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus


# ==================================================
# PROMETHEUS CONFIGURATION
# ==================================================

echo "Creating Prometheus configuration..."

sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
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


sudo chown prometheus:prometheus \
/etc/prometheus/prometheus.yml


# ==================================================
# PROMETHEUS SERVICE
# ==================================================

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
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


sudo systemctl daemon-reload

sudo systemctl enable prometheus
sudo systemctl start prometheus


# ==================================================
# GRAFANA
# ==================================================

echo "Installing Grafana..."

sudo mkdir -p /etc/apt/keyrings

wget -q -O \
/tmp/grafana.key \
https://apt.grafana.com/gpg-full.key

sudo mv /tmp/grafana.key \
/etc/apt/keyrings/grafana.asc

sudo chmod 644 \
/etc/apt/keyrings/grafana.asc


echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" \
| sudo tee /etc/apt/sources.list.d/grafana.list


sudo apt update

sudo apt install -y grafana


# ==================================================
# START GRAFANA
# ==================================================

sudo systemctl daemon-reload

sudo systemctl enable grafana-server
sudo systemctl start grafana-server


# ==================================================
# CHECK SERVICES
# ==================================================

echo ""
echo "=========================================="
echo " Checking Services"
echo "=========================================="

echo ""
echo "Node Exporter:"
sudo systemctl is-active node_exporter

echo ""
echo "Prometheus:"
sudo systemctl is-active prometheus

echo ""
echo "Grafana:"
sudo systemctl is-active grafana-server


# ==================================================
# LOCAL TESTS
# ==================================================

echo ""
echo "=========================================="
echo " Testing Services"
echo "=========================================="

echo ""
echo "Node Exporter:"
curl -s http://localhost:9100/metrics | head

echo ""
echo "Prometheus:"
curl -s http://localhost:9090/-/healthy

echo ""
echo "Grafana:"
curl -s http://localhost:3000/api/health


echo ""
echo "=========================================="
echo " Installation Completed"
echo "=========================================="

echo ""
echo "Grafana  : http://SERVER-IP:3000"
echo "Prometheus: http://SERVER-IP:9090"
echo "Node Exporter: http://SERVER-IP:9100"

echo ""
echo "Default Grafana login:"
echo "Username: admin"
echo "Password: admin"

echo ""