# AWS Monitoring Platform

Terraform + GitHub Actions project to create an AWS EC2 monitoring server.

## Architecture

GitHub
   |
   v
GitHub Actions
   |
   v
Terraform
   |
   v
AWS EC2
   |
   +-- Node Exporter :9100
   |
   +-- Prometheus :9090
   |
   +-- Grafana :3000


## Components

- Terraform
- AWS EC2
- Prometheus
- Grafana
- Node Exporter
- GitHub Actions


## Deployment

Clone the repository:

git clone <repository-url>

cd aws-monitoring-platform/terraform


Copy variables:

cp terraform.tfvars.example terraform.tfvars


Update `terraform.tfvars`:

- Set `allowed_ssh_cidr` to your public IPv4 address in CIDR format, for example `203.0.113.45/32`
- Set `allowed_grafana_cidr` to your public IPv4 address in CIDR format, for example `203.0.113.45/32`

You can find your public IP at a service such as `https://ifconfig.me` or `https://whatismyipaddress.com`.


Initialize Terraform:

terraform init


Validate:

terraform validate


Plan:

terraform plan


Apply:

terraform apply


Get outputs:

terraform output


Grafana:

http://<EC2-PUBLIC-IP>:3000


## Prometheus

Prometheus runs internally on:

http://localhost:9090


Node Exporter:

http://localhost:9100