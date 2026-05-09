output "instance_public_ip" {
  value       = aws_lightsail_instance.staging.public_ip_address
  description = "Set STAGING_SERVER_IP GitHub secret and config/deploy/staging.rb to this value"
}

output "db_endpoint" {
  value       = aws_lightsail_database.staging.master_endpoint_address
  description = "Update DATABASE_URL in /etc/stocks/env on the server with this host"
}

output "db_port" {
  value = aws_lightsail_database.staging.master_endpoint_port
}

output "lb_dns" {
  value       = aws_lightsail_lb.staging.dns_name
  description = "Point your staging DNS CNAME to this load balancer address"
}

output "lb_certificate_validation_records" {
  value       = aws_lightsail_lb_certificate.staging.domain_validation_records
  description = "Create these DNS records if the staging load balancer certificate needs validation"
}
