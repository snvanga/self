# Health checks for services exposed by the monitoring instance
# The HTTP data source runs from where Terraform is executed and will
# attempt to fetch Grafana's health endpoint. This only works when
# Grafana is reachable from the machine running Terraform.

data "http" "grafana_health" {
  count = var.enable_grafana_health_check ? 1 : 0
  url = "http://${aws_instance.monitoring.public_ip}:3000/api/health"
  request_headers = {
    Accept = "application/json"
  }

  # ensure TF waits for the instance to be created first
  depends_on = [aws_instance.monitoring]
}

data "external" "service_status" {
  count      = var.enable_ssh_health_check ? 1 : 0
  program    = ["bash", "${path.module}/scripts/check_services.sh", aws_instance.monitoring.public_ip, var.ssh_user, var.ssh_private_key_path]
  depends_on = [aws_instance.monitoring]
}
