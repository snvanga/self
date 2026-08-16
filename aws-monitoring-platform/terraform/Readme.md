# Grafana EC2 Setup

Terraform project that creates an Ubuntu EC2 instance and installs Grafana only.

## Required values

Update the values in `terraform.tfvars` before deployment:

- `aws_region`: AWS region, for example `ap-south-1`
- `ami_id`: Ubuntu AMI ID for the chosen region
- `instance_type`: EC2 instance type, for example `t2.small`
- `key_name`: existing EC2 key pair name
- `allowed_ssh_cidr`: your public IP in CIDR format, for example `203.0.113.45/32`
- `allowed_grafana_cidr`: your public IP in CIDR format, for example `203.0.113.45/32`

## Deploy

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

## Access Grafana

After the instance is up, open:

```text
http://<EC2_PUBLIC_IP>:3000
```

Default login:

```text
Username: admin
Password: admin
```

You will be prompted to change the password on first login.