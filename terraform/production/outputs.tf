output "instance_public_ip" {
  value       = aws_lightsail_instance.production.public_ip_address
  description = "Set PRODUCTION_SERVER_IP in config/deploy/production.rb to this value"
}

output "db_endpoint" {
  value       = aws_lightsail_database.production.master_endpoint_address
  description = "Database endpoint for DATABASE_URL in /etc/stocks/env"
}

output "db_port" {
  value = aws_lightsail_database.production.master_endpoint_port
}

output "lb_dns" {
  value       = aws_lightsail_lb.production.dns_name
  description = "Load balancer DNS name - point your production DNS CNAME here"
}
