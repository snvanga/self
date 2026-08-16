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