output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.monitoring.id
}

output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.monitoring.public_ip
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "prometheus_internal_url" {
  description = "Prometheus internal URL"
  value       = "http://localhost:9090"
}

output "grafana_health_status_code" {
  description = "HTTP status code returned by Grafana /api/health (0 if unreachable)"
  value       = try(data.http.grafana_health.status_code, 0)
}

output "grafana_health_body" {
  description = "Response body from Grafana /api/health (empty if unreachable)"
  value       = try(data.http.grafana_health.response_body, "")
}

output "grafana_service_status" {
  description = "Raw systemctl status output for grafana-server fetched over SSH (empty when SSH check disabled)"
  value       = var.enable_ssh_health_check ? try(data.external.service_status[0].result.grafana, "") : ""
}

output "prometheus_service_status" {
  description = "Raw systemctl status output for prometheus fetched over SSH (empty when SSH check disabled)"
  value       = var.enable_ssh_health_check ? try(data.external.service_status[0].result.prometheus, "") : ""
}

output "node_exporter_service_status" {
  description = "Raw systemctl status output for node_exporter fetched over SSH (empty when SSH check disabled)"
  value       = var.enable_ssh_health_check ? try(data.external.service_status[0].result.node_exporter, "") : ""
}