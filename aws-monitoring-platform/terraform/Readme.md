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


Update `terraform.tfvars` with real values:

- `aws_region`: your AWS region, for example `ap-south-1`
- `ami_id`: a valid Ubuntu AMI ID for your region
- `instance_type`: EC2 instance type
- `key_name`: existing EC2 key pair name in your AWS account
- `allowed_ssh_cidr`: your public IPv4 address in CIDR format, for example `203.0.113.45/32`
- `allowed_grafana_cidr`: your public IPv4 address in CIDR format, for example `203.0.113.45/32`

You can find your public IP at a service such as `https://ifconfig.me` or `https://whatismyipaddress.com`.

You also need AWS credentials configured locally before running Terraform.

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

Service health checks

- After `terraform apply`, you can run `terraform output grafana_health_status_code` to see the HTTP status code returned by Grafana's `/api/health` endpoint (0 if unreachable from your machine).
- You can also view the raw JSON by running `terraform output grafana_health_body`.

Note: the health check is performed from the machine where you run Terraform. If Grafana is only reachable from inside the VPC or the instance itself, the health check may show unreachable (0). In that case SSH to the instance and curl the localhost endpoints:

```bash
ssh monitoring
curl -I http://127.0.0.1:3000
curl -I http://127.0.0.1:9090
```

## Prometheus

Prometheus runs internally on:

http://localhost:9090


Node Exporter:

http://localhost:9100